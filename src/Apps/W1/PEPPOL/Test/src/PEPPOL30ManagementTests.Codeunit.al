// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Test;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Peppol;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using Microsoft.Service.Test;
using System.Environment.Configuration;
using System.Utilities;

codeunit 139235 "PEPPOL30 Management Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInvt: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXMLRead: Codeunit "Library - XPath XML Reader";
        IsInitialized: Boolean;
        FieldMustHaveValueErr: Label '%1 must have a value', Comment = '%1 - Field caption';
        InvoiceDiscAmtTxt: Label 'Line Discount Amount';
        InvoiceElectronicallySendPEPPOLFormatTxt: Label 'The Invoice File Successfully Sent in PEPPOL Format';
        NegativeUnitPriceErr: Label 'It cannot be negative if you want to send the posted document as an electronic document. \\Do you want to continue?', Comment = '%1 - record ID';
        NoInternationalStandardCodeErr: Label 'You must specify a valid International Standard Code for the Unit of Measure for %1.', Comment = '%1 - Unit of Measure Code';
        NoItemDescriptionErr: Label 'Description field is empty.';
        NoUnitOfMeasureErr: Label 'The Invoice %1 contains lines on which the Unit of Measure Code field is empty.', Comment = '%1 - Invoice Number';
        SalespersonTxt: Label 'Salesperson';

    [Test]
    procedure GeneralInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        SalesInvoiceNo: Code[20];
        AccountingCost: Text;
        DocumentCurrencyCode: Text;
        DocumentCurrencyCodeListID: Text;
        ID: Text;
        InvoiceTypeCode: Text;
        InvoiceTypeCodeListID: Text;
        IssueDate: Text;
        Note: Text;
        TaxCurrencyCode: Text;
        TaxCurrencyCodeListID: Text;
        TaxPointDate: Text;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        Cust.Validate("Currency Code", CreateCurrencyCode());
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // Post and get Sales Invoice No.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesHeader.TransferFields(SalesInvoiceHeader);

        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetGeneralInfo(
          SalesHeader,
          ID,
          IssueDate,
          InvoiceTypeCode,
          InvoiceTypeCodeListID,
          Note,
          TaxPointDate,
          DocumentCurrencyCode,
          DocumentCurrencyCodeListID,
          TaxCurrencyCode,
          TaxCurrencyCodeListID,
          AccountingCost);

        Assert.AreEqual(SalesInvoiceNo, ID, '');
        Assert.AreEqual(Format(SalesHeader."Document Date", 0, 9), IssueDate, '');
        Assert.AreEqual('380', InvoiceTypeCode, '');
        Assert.AreEqual('UNCL1001', InvoiceTypeCodeListID, '');
        Assert.AreEqual('', Note, '');
        Assert.AreEqual('', TaxPointDate, '');
        Assert.AreEqual(SalesHeader."Currency Code", DocumentCurrencyCode, '');
        Assert.AreEqual('ISO4217', DocumentCurrencyCodeListID, '');
        Assert.AreEqual(DocumentCurrencyCode, TaxCurrencyCode, '');
        Assert.AreEqual('ISO4217', TaxCurrencyCodeListID, '');
        Assert.AreEqual('', AccountingCost, '');
    end;

    [Test]
    procedure GetInvoicePeriodInfo()
    var
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        EndDate: Text;
        StartDate: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetInvoicePeriodInfo(StartDate, EndDate);

        // Verify
        Assert.AreEqual('', StartDate, '');
        Assert.AreEqual('', EndDate, '');
    end;

    [Test]
    procedure GetOrderReferenceInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        OrderReferenceID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);

        // Verify
        Assert.AreEqual(SalesHeader."External Document No.", OrderReferenceID, '');
    end;

    [Test]
    procedure GetContractDocRef()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        ContractDocumentReferenceID: Text;
        ContractRefDocTypeCodeListID: Text;
        DocumentType: Text;
        DocumentTypeCode: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetContractDocRefInfo(
          SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);

        // Verify
        Assert.AreEqual(SalesHeader."No.", ContractDocumentReferenceID, '');
        Assert.AreEqual('', DocumentTypeCode, '');
        Assert.AreEqual('UNCL1001', ContractRefDocTypeCodeListID, '');
        Assert.AreEqual('', DocumentType, '');
    end;

    [Test]
    procedure GetAdditionalDocRefInfo()
    var
        SalesHeader: Record "Sales Header";
        PEPPOLAttachmentProvider: Interface "PEPPOL Attachment Provider";
        AdditionalDocRefDocumentType: Text;
        AdditionalDocumentReferenceID: Text;
        EmbeddedDocumentBinaryObject: Text;
        MimeCode: Text;
        URI: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLAttachmentProvider := GetFormat();
        PEPPOLAttachmentProvider.GetAdditionalDocRefInfo(
          SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, EmbeddedDocumentBinaryObject, 0);

        // Verify
        Assert.AreEqual('', AdditionalDocumentReferenceID, '');
        Assert.AreEqual('', AdditionalDocRefDocumentType, '');
        Assert.AreEqual('', URI, '');
        Assert.AreEqual('', MimeCode, '');
        Assert.AreEqual('', EmbeddedDocumentBinaryObject, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyInfo()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        NewGLNNo: Code[13];
        SupplierEndpointID: Text;
        SupplierName: Text;
        SupplierSchemeID: Text;
    begin
        // Setup
        Initialize();

        NewGLNNo := LibraryUtility.GenerateGUID();

        CompanyInfo.Get();
        CompanyInfo.GLN := NewGLNNo;
        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo.Name := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);

        // Verify
        Assert.AreEqual(NewGLNNo, SupplierEndpointID, '');
        Assert.AreEqual('GLN', SupplierSchemeID, '');
        Assert.AreEqual(CompanyInfo.Name, SupplierName, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyInfo_VATRegNo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        SupplierEndpointID: Text;
        SupplierName: Text;
        SupplierSchemeID: Text;
    begin
        LibraryERM.FindCountryRegion(CountryRegion);

        // Setup
        CompanyInfo.Get();
        CompanyInfo.GLN := '';
        CompanyInfo."Country/Region Code" := CountryRegion.Code;
        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        CountryRegion.Get(CompanyInfo."Country/Region Code");
        CountryRegion."VAT Scheme" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyInfo(SupplierEndpointID, SupplierSchemeID, SupplierName);

        // Verify
        Assert.AreEqual(CompanyInfo."VAT Registration No.", SupplierEndpointID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", SupplierSchemeID, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyPostalAddr()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CityName: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
        PostalZone: Text;
        StreetName: Text;
        SupplierAdditionalStreetName: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();
        CompanyInfo.Address := LibraryUtility.GenerateGUID();
        CompanyInfo."Address 2" := LibraryUtility.GenerateGUID();
        CompanyInfo.City := LibraryUtility.GenerateGUID();
        CompanyInfo."Post Code" := LibraryUtility.GenerateGUID();
        CompanyInfo.County := LibraryUtility.GenerateGUID();
        CreateCountryRegion(CountryRegion);
        CompanyInfo."Country/Region Code" := CountryRegion.Code;
        CompanyInfo."Responsibility Center" := '';
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyPostalAddr(
          DummySalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        // Verify
        Assert.AreEqual(CompanyInfo.Address, StreetName, '');
        Assert.AreEqual(CompanyInfo."Address 2", SupplierAdditionalStreetName, '');
        Assert.AreEqual(CompanyInfo.City, CityName, '');
        Assert.AreEqual(CompanyInfo."Post Code", PostalZone, '');
        Assert.AreEqual(CompanyInfo.County, CountrySubentity, '');
        Assert.AreEqual(CountryRegion."ISO Code", IdentificationCode, ''); // TFS ID 376447
        Assert.AreEqual('ISO3166-1:Alpha2', ListID, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyPostalAddr_RespCenter()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        RespCenter: Record "Responsibility Center";
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CityName: Text;
        CountrySubentity: Text;
        IdentificationCode: Text;
        ListID: Text;
        PostalZone: Text;
        StreetName: Text;
        SupplierAdditionalStreetName: Text;
    begin
        // Setup
        Initialize();

        RespCenter.Init();
        RespCenter.Code := LibraryUtility.GenerateGUID();
        RespCenter.Address := LibraryUtility.GenerateGUID();
        RespCenter."Address 2" := LibraryUtility.GenerateGUID();
        RespCenter.City := LibraryUtility.GenerateGUID();
        RespCenter."Post Code" := LibraryUtility.GenerateGUID();
        RespCenter.County := LibraryUtility.GenerateGUID();
        CreateCountryRegion(CountryRegion);
        RespCenter."Country/Region Code" := CountryRegion.Code;
        RespCenter.Insert(false);

        CompanyInfo.Get();
        CompanyInfo."Responsibility Center" := RespCenter.Code;
        CompanyInfo.Modify(false);

        DummySalesHeader."Responsibility Center" := RespCenter.Code;

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyPostalAddr(
          DummySalesHeader, StreetName, SupplierAdditionalStreetName, CityName, PostalZone, CountrySubentity, IdentificationCode, ListID);

        // Verify
        Assert.AreEqual(RespCenter.Address, StreetName, '');
        Assert.AreEqual(RespCenter."Address 2", SupplierAdditionalStreetName, '');
        Assert.AreEqual(RespCenter.City, CityName, '');
        Assert.AreEqual(RespCenter."Post Code", PostalZone, '');
        Assert.AreEqual(RespCenter.County, CountrySubentity, '');
        Assert.AreEqual(CountryRegion."ISO Code", IdentificationCode, ''); // TFS ID 376447
        Assert.AreEqual('ISO3166-1:Alpha2', ListID, '');

        // Tear down
        RespCenter.Delete(true);
        CompanyInfo.Validate("Responsibility Center", '');
        CompanyInfo.Modify(true);
    end;

    [Test]
    procedure GetAccountingSupplierPartyTaxScheme()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        CountryRegion.Get(CompanyInfo."Country/Region Code");
        CountryRegion."VAT Scheme" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);

        // Verify
        Assert.AreEqual(CompanyInfo."Country/Region Code" + CompanyInfo."VAT Registration No.", CompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CompanyIDSchemeID, '');
        Assert.AreEqual('VAT', TaxSchemeID, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyLegalEntity_GLN()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        PartyLegalEntityCompanyID: Text;
        PartyLegalEntityRegName: Text;
        PartyLegalEntitySchemeID: Text;
        SupplierRegAddrCityName: Text;
        SupplierRegAddrCountryIdCode: Text;
        SupplRegAddrCountryIdListId: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();
        CompanyInfo.GLN := LibraryUtility.GenerateGUID();
        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyLegalEntity(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName,
          SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);

        // Verify
        Assert.AreEqual(CompanyInfo.Name, PartyLegalEntityRegName, '');
        Assert.AreEqual(CompanyInfo.GLN, PartyLegalEntityCompanyID, '');
        Assert.AreEqual('GLN', PartyLegalEntitySchemeID, '');

        Assert.AreEqual(CompanyInfo.City, SupplierRegAddrCityName, '');
        Assert.AreEqual(CompanyInfo."Country/Region Code", SupplierRegAddrCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', SupplRegAddrCountryIdListId, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyLegalEntity_VATRegNo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        PartyLegalEntityCompanyID: Text;
        PartyLegalEntityRegName: Text;
        PartyLegalEntitySchemeID: Text;
        SupplierRegAddrCityName: Text;
        SupplierRegAddrCountryIdCode: Text;
        SupplRegAddrCountryIdListId: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();
        CompanyInfo.GLN := '';
        CompanyInfo."Use GLN in Electronic Document" := true;
        if CompanyInfo."Country/Region Code" = '' then begin
            CountryRegion.FindFirst();
            CompanyInfo.Validate("Country/Region Code", CountryRegion.Code)
        end;
        if CompanyInfo."VAT Registration No." = '' then
            CompanyInfo."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInfo."Country/Region Code");
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyLegalEntity(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName,
          SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);

        // Verify
        CountryRegion.Get(CompanyInfo."Country/Region Code");
        Assert.AreEqual(CompanyInfo.Name, PartyLegalEntityRegName, '');
        Assert.AreEqual(CompanyInfo."VAT Registration No.", PartyLegalEntityCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", PartyLegalEntitySchemeID, '');

        Assert.AreEqual(CompanyInfo.City, SupplierRegAddrCityName, '');
        Assert.AreEqual(CompanyInfo."Country/Region Code", SupplierRegAddrCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', SupplRegAddrCountryIdListId, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyContact()
    var
        CompanyInfo: Record "Company Information";
        DummySalesHeader: Record "Sales Header";
        Salesperson: Record "Salesperson/Purchaser";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        ContactID: Text;
        ContactName: Text;
        ElectronicMail: Text;
        Telefax: Text;
        Telephone: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();
        CompanyInfo."Telex No." := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        Salesperson.Init();
        Salesperson.Code := LibraryUtility.GenerateGUID();
        Salesperson.Name := LibraryUtility.GenerateGUID();
        Salesperson."Phone No." := LibraryUtility.GenerateGUID();
        Salesperson."E-Mail" := LibraryUtility.GenerateRandomEmail();
        Salesperson.Insert(false);

        DummySalesHeader."Salesperson Code" := Salesperson.Code;

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingSupplierPartyContact(DummySalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);

        // Verify
        Assert.AreEqual(Format(SalespersonTxt), ContactID, '');
        Assert.AreEqual(Salesperson.Name, ContactName, '');
        Assert.AreEqual(Salesperson."Phone No.", Telephone, '');
        Assert.AreEqual(CompanyInfo."Telex No.", Telefax, '');
        Assert.AreEqual(Salesperson."E-Mail", ElectronicMail, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyInfo()
    var
        Cust: Record Customer;
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustomerEndpointID: Text;
        CustomerName: Text;
        CustomerPartyIdentificationID: Text;
        CustomerPartyIDSchemeID: Text;
        CustomerSchemeID: Text;
        NewGLNNo: Text[13];
    begin
        // Setup for GLN
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        NewGLNNo := LibraryUtility.GenerateGUID();

        Cust.GLN := NewGLNNo;
        Cust."Use GLN in Electronic Document" := true;
        Cust.Modify(false);

        DummySalesHeader."Bill-to Customer No." := Cust."No.";
        DummySalesHeader."Bill-to Name" := Cust.Name;

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyInfo(
          DummySalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);

        // Verify
        Assert.AreEqual(NewGLNNo, CustomerEndpointID, '');
        Assert.AreEqual('GLN', CustomerSchemeID, '');
        Assert.AreEqual(NewGLNNo, CustomerPartyIdentificationID, '');
        Assert.AreEqual('GLN', CustomerPartyIDSchemeID, '');
        Assert.AreEqual(DummySalesHeader."Bill-to Name", CustomerName, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyInfo_VATRegNo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        Cust: Record Customer;
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustomerEndpointID: Text;
        CustomerName: Text;
        CustomerPartyIdentificationID: Text;
        CustomerPartyIDSchemeID: Text;
        CustomerSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);

        DummySalesHeader."VAT Registration No." := LibraryUtility.GenerateGUID();
        DummySalesHeader."Bill-to Customer No." := Cust."No.";
        DummySalesHeader."Bill-to Name" := Cust.Name;

        CompanyInfo.Get();
        CountryRegion.Get(CompanyInfo."Country/Region Code");
        DummySalesHeader."Bill-to Country/Region Code" := CompanyInfo."Country/Region Code";

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyInfo(
          DummySalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);

        // Verify
        Assert.AreEqual(DummySalesHeader."VAT Registration No.", CustomerEndpointID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CustomerSchemeID, '');
        Assert.AreEqual('', CustomerPartyIdentificationID, '');
        Assert.AreEqual('GLN', CustomerPartyIDSchemeID, '');
        Assert.AreEqual(DummySalesHeader."Bill-to Name", CustomerName, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyPostalAddr()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustomerAdditionalStreetName: Text;
        CustomerCityName: Text;
        CustomerCountrySubentity: Text;
        CustomerIdentificationCode: Text;
        CustomerListID: Text;
        CustomerPostalZone: Text;
        CustomerStreetName: Text;
    begin
        // Setup
        Initialize();

        SalesHeader.Init();
        SalesHeader."Bill-to Address" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to Address 2" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to City" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to Post Code" := LibraryUtility.GenerateGUID();
        SalesHeader."Bill-to County" := LibraryUtility.GenerateGUID();
        CreateCountryRegion(CountryRegion);
        SalesHeader."Bill-to Country/Region Code" := CountryRegion.Code;

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyPostalAddr(
          SalesHeader, CustomerStreetName, CustomerAdditionalStreetName, CustomerCityName, CustomerPostalZone, CustomerCountrySubentity,
          CustomerIdentificationCode, CustomerListID);

        // Verify
        Assert.AreEqual(SalesHeader."Bill-to Address", CustomerStreetName, '');
        Assert.AreEqual(SalesHeader."Bill-to Address 2", CustomerAdditionalStreetName, '');
        Assert.AreEqual(SalesHeader."Bill-to City", CustomerCityName, '');
        Assert.AreEqual(SalesHeader."Bill-to Post Code", CustomerPostalZone, '');
        Assert.AreEqual(SalesHeader."Bill-to County", CustomerCountrySubentity, '');
        Assert.AreEqual(CountryRegion."ISO Code", CustomerIdentificationCode, ''); // TFS ID 376447
        Assert.AreEqual('ISO3166-1:Alpha2', CustomerListID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyTaxScheme()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // Setup
        Initialize();

        CompanyInfo.Get();

        CountryRegion.Get(CompanyInfo."Country/Region Code");
        CountryRegion."VAT Scheme" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify(false);

        DummySalesHeader."VAT Registration No." := LibraryUtility.GenerateGUID();
        DummySalesHeader."Bill-to Country/Region Code" := CompanyInfo."Country/Region Code";

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyTaxScheme(
          DummySalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);

        // Verify
        Assert.AreEqual(DummySalesHeader."VAT Registration No.", CustPartyTaxSchemeCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CustPartyTaxSchemeCompIDSchID, '');
        Assert.AreEqual('VAT', CustTaxSchemeID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyLegalEntity_GLN()
    var
        CountryRegion: Record "Country/Region";
        Cust: Record Customer;
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyLegalEntityCompanyID: Text;
        CustPartyLegalEntityIDSchemeID: Text;
        CustPartyLegalEntityRegName: Text;
    begin
        // Setup
        Initialize();
        CountryRegion.FindFirst();
        LibrarySales.CreateCustomer(Cust);
        Cust."Country/Region Code" := CountryRegion.Code;
        Cust.GLN := LibraryUtility.GenerateGUID();
        Cust."Use GLN in Electronic Document" := true;
        Cust.Modify(false);

        DummySalesHeader.Validate("Bill-to Customer No.", Cust."No.");

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyLegalEntity(
          DummySalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);

        // Verify
        Assert.AreEqual(Cust.Name, CustPartyLegalEntityRegName, '');
        Assert.AreEqual(Cust.GLN, CustPartyLegalEntityCompanyID, '');
        Assert.AreEqual('GLN', CustPartyLegalEntityIDSchemeID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyLegalEntity_VATRegNo()
    var
        CountryRegion: Record "Country/Region";
        Cust: Record Customer;
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyLegalEntityCompanyID: Text;
        CustPartyLegalEntityIDSchemeID: Text;
        CustPartyLegalEntityRegName: Text;
    begin
        // Setup
        Initialize();
        CountryRegion.FindFirst();
        LibrarySales.CreateCustomer(Cust);
        Cust."Country/Region Code" := CountryRegion.Code;
        Cust."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Cust.GLN := '';
        Cust."Use GLN in Electronic Document" := true;
        Cust.Modify(false);

        DummySalesHeader.Validate("Bill-to Customer No.", Cust."No.");
        DummySalesHeader.Validate("VAT Registration No.", Cust."VAT Registration No.");

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyLegalEntity(
          DummySalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);

        // Verify
        Assert.AreEqual(Cust.Name, CustPartyLegalEntityRegName, '');
        Assert.AreEqual(Cust."VAT Registration No.", CustPartyLegalEntityCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CustPartyLegalEntityIDSchemeID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyContact()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustContactElectronicMail: Text;
        CustContactID: Text;
        CustContactName: Text;
        CustContactTelefax: Text;
        CustContactTelephone: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252033] GetAccountingCustomerPartyContact returns Bill-to Name when Contact is blank as ContactName
        Initialize();

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer."Phone No." := LibraryUtility.GenerateGUID();
        Customer."E-Mail" := LibraryUtility.GenerateGUID();
        Customer.Insert(false);

        DummySalesHeader."Bill-to Customer No." := Customer."No.";
        DummySalesHeader."Bill-to Name" := LibraryUtility.GenerateGUID();

        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyContact(
          DummySalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);

        Assert.AreEqual(DummySalesHeader."Bill-to Name", CustContactName, '');
        Assert.AreEqual(Customer."Phone No.", CustContactTelephone, '');
        Assert.AreEqual(Customer."E-Mail", CustContactElectronicMail, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyContactName()
    var
        DummySalesHeader: Record "Sales Header";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustContactElectronicMail: Text;
        CustContactID: Text;
        CustContactName: Text;
        CustContactTelefax: Text;
        CustContactTelephone: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252033] GetAccountingCustomerPartyContact returns Bill-to Contact when not blank as ContactName
        Initialize();

        DummySalesHeader."Bill-to Name" := LibraryUtility.GenerateGUID();
        DummySalesHeader."Bill-to Contact" := LibraryUtility.GenerateGUID();

        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyContact(
          DummySalesHeader, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);

        Assert.AreEqual(DummySalesHeader."Bill-to Contact", CustContactName, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetPayeePartyInfo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        NewGLNNo: Code[13];
        NewVATNo: Code[20];
        NewName: Code[50];
        PayeePartyID: Text;
        PayeePartyIDSchemeID: Text;
        PayeePartyLegalCompIDSchemeID: Text;
        PayeePartyLegalEntityCompanyID: Text;
        PayeePartyNameName: Text;
    begin
        // Setup
        Initialize();

        NewGLNNo := LibraryUtility.GenerateGUID();
        NewVATNo := LibraryUtility.GenerateGUID();
        NewName := LibraryUtility.GenerateGUID();

        CompanyInfo.Get();
        CompanyInfo.GLN := NewGLNNo;
        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo."VAT Registration No." := NewVATNo;
        CompanyInfo.Name := NewName;
        CompanyInfo."Country/Region Code" := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        CountryRegion.Code := CompanyInfo."Country/Region Code";
        CountryRegion.Insert(false);
        LibraryUtility.FillFieldMaxText(CountryRegion, CountryRegion.FieldNo("VAT Scheme"));
        CountryRegion.Get(CompanyInfo."Country/Region Code");

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetPayeePartyInfo(
          PayeePartyID, PayeePartyIDSchemeID, PayeePartyNameName, PayeePartyLegalEntityCompanyID, PayeePartyLegalCompIDSchemeID);

        // Verify
        Assert.AreEqual(NewGLNNo, PayeePartyID, '');
        Assert.AreEqual('GLN', PayeePartyIDSchemeID, '');
        Assert.AreEqual(NewName, PayeePartyNameName, '');
        Assert.AreEqual(NewVATNo, PayeePartyLegalEntityCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", PayeePartyLegalCompIDSchemeID, '');
    end;

    [Test]
    procedure GetTaxRepresentativePartyInfo()
    var
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        PayeePartyTaxSchCompIDSchemeID: Text;
        PayeePartyTaxSchemeCompanyID: Text;
        PayeePartyTaxSchemeTaxSchemeID: Text;
        TaxRepPartyNameName: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetTaxRepresentativePartyInfo(
          TaxRepPartyNameName, PayeePartyTaxSchemeCompanyID, PayeePartyTaxSchCompIDSchemeID, PayeePartyTaxSchemeTaxSchemeID);

        // Verify
        Assert.AreEqual('', TaxRepPartyNameName, '');
        Assert.AreEqual('', PayeePartyTaxSchemeCompanyID, '');
        Assert.AreEqual('', PayeePartyTaxSchCompIDSchemeID, '');
        Assert.AreEqual('', PayeePartyTaxSchemeTaxSchemeID, '');
    end;

    [Test]
    procedure GetDeliveryInfo()
    var
        PEPPOLDeliveryInfoProvider: Interface "PEPPOL Delivery Info Provider";
        ActualDeliveryDate: Text;
        DeliveryID: Text;
        DeliveryIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLDeliveryInfoProvider := GetFormat();
        PEPPOLDeliveryInfoProvider.GetDeliveryInfo(ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);

        // Verify
        Assert.AreEqual('', ActualDeliveryDate, '');
        Assert.AreEqual('', DeliveryID, '');
        Assert.AreEqual('', DeliveryIDSchemeID, '');
    end;

    [Test]
    procedure GetDeliveryAddress()
    var
        CountryRegion: Record "Country/Region";
        DummySalesHeader: Record "Sales Header";
        PEPPOLDeliveryInfoProvider: Interface "PEPPOL Delivery Info Provider";
        DeliveryAdditionalStreetName: Text;
        DeliveryCityName: Text;
        DeliveryCountryIdCode: Text;
        DeliveryCountryListID: Text;
        DeliveryCountrySubentity: Text;
        DeliveryPostalZone: Text;
        DeliveryStreetName: Text;
    begin
        // Setup
        Initialize();

        DummySalesHeader."Ship-to Address" := LibraryUtility.GenerateGUID();
        DummySalesHeader."Ship-to Address 2" := LibraryUtility.GenerateGUID();
        DummySalesHeader."Ship-to City" := LibraryUtility.GenerateGUID();
        DummySalesHeader."Ship-to Post Code" := LibraryUtility.GenerateGUID();
        DummySalesHeader."Ship-to County" := LibraryUtility.GenerateGUID();
        CreateCountryRegion(CountryRegion);
        DummySalesHeader."Ship-to Country/Region Code" := CountryRegion.Code;

        // Exercise
        PEPPOLDeliveryInfoProvider := GetFormat();
        PEPPOLDeliveryInfoProvider.GetDeliveryAddress(
          DummySalesHeader, DeliveryStreetName, DeliveryAdditionalStreetName, DeliveryCityName, DeliveryPostalZone, DeliveryCountrySubentity,
          DeliveryCountryIdCode, DeliveryCountryListID);

        // Verify
        Assert.AreEqual(DummySalesHeader."Ship-to Address", DeliveryStreetName, '');
        Assert.AreEqual(DummySalesHeader."Ship-to Address 2", DeliveryAdditionalStreetName, '');
        Assert.AreEqual(DummySalesHeader."Ship-to City", DeliveryCityName, '');
        Assert.AreEqual(DummySalesHeader."Ship-to Post Code", DeliveryPostalZone, '');
        Assert.AreEqual(DummySalesHeader."Ship-to County", DeliveryCountrySubentity, '');
        Assert.AreEqual(CountryRegion."ISO Code", DeliveryCountryIdCode, ''); // TFS ID 376447
        Assert.AreEqual('ISO3166-1:Alpha2', DeliveryCountryListID, '');
    end;

    [Test]
    procedure GetPaymentMeansInfo()
    var
        DummySalesHeader: Record "Sales Header";
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        NetworkID: Text;
        PaymentChannelCode: Text;
        PaymentDueDate: Text;
        PaymentID: Text;
        PaymentMeansCode: Text;
        PaymentMeansListID: Text;
        PrimaryAccountNumberID: Text;
    begin
        // Setup
        Initialize();

        DummySalesHeader."Due Date" := LibraryRandom.RandDate(10);

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansInfo(
          DummySalesHeader, PaymentMeansCode, PaymentMeansListID, PaymentDueDate, PaymentChannelCode, PaymentID,
          PrimaryAccountNumberID, NetworkID);

        // Verify
        Assert.AreEqual('31', PaymentMeansCode, '');
        Assert.AreEqual('UNCL4461', PaymentMeansListID, '');
        Assert.AreEqual(Format(DummySalesHeader."Due Date", 0, 9), PaymentDueDate, '');
        Assert.AreEqual('', PaymentChannelCode, '');
        Assert.AreEqual('', PaymentID, '');
        Assert.AreEqual('', PrimaryAccountNumberID, '');
        Assert.AreEqual('', NetworkID, '');
    end;

    [Test]
    procedure GetPaymentsMeansPayeeFinancialAcc()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        FinancialInstitutionBranchID: Text;
        FinancialInstitutionID: Text;
        FinancialInstitutionName: Text;
        FinancialInstitutionSchemeID: Text;
        PayeeFinancialAccountID: Text;
        PaymentMeansSchemeID: Text;
    begin
        // Setup for IBAN
        Initialize();

        CompanyInfo.Get();
        CompanyInfo."Bank Branch No." := LibraryUtility.GenerateGUID();
        CompanyInfo."SWIFT Code" := LibraryUtility.GenerateGUID();
        CompanyInfo."Bank Name" := LibraryUtility.GenerateGUID();
        CompanyInfo.IBAN := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansPayeeFinancialAcc(
          PayeeFinancialAccountID, PaymentMeansSchemeID, FinancialInstitutionBranchID, FinancialInstitutionID,
          FinancialInstitutionSchemeID, FinancialInstitutionName);

        // Verify
        Assert.AreEqual(CompanyInfo.IBAN, PayeeFinancialAccountID, '');
        Assert.AreEqual('IBAN', PaymentMeansSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Branch No.", FinancialInstitutionBranchID, '');
        Assert.AreEqual(CompanyInfo."SWIFT Code", FinancialInstitutionID, '');
        Assert.AreEqual('BIC', FinancialInstitutionSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Name", FinancialInstitutionName, '');
    end;

    [Test]
    procedure GetPaymentsMeansPayeeFinancialAcc_Spaces()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        FinancialInstitutionBranchID: Text;
        FinancialInstitutionID: Text;
        FinancialInstitutionName: Text;
        FinancialInstitutionSchemeID: Text;
        PayeeFinancialAccountID: Text;
        PaymentMeansSchemeID: Text;
    begin
        // Setup for IBAN
        Initialize();

        CompanyInfo.Get();
        CompanyInfo."Bank Branch No." := LibraryUtility.GenerateGUID();
        CompanyInfo."SWIFT Code" := 'S W I F T 1 2 3';
        CompanyInfo."Bank Name" := LibraryUtility.GenerateGUID();
        CompanyInfo.IBAN := 'I B A N 12 3';
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansPayeeFinancialAcc(
          PayeeFinancialAccountID, PaymentMeansSchemeID, FinancialInstitutionBranchID, FinancialInstitutionID,
          FinancialInstitutionSchemeID, FinancialInstitutionName);

        // Verify
        Assert.AreEqual('IBAN123', PayeeFinancialAccountID, '');
        Assert.AreEqual('IBAN', PaymentMeansSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Branch No.", FinancialInstitutionBranchID, '');
        Assert.AreEqual('SWIFT123', FinancialInstitutionID, '');
        Assert.AreEqual('BIC', FinancialInstitutionSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Name", FinancialInstitutionName, '');
    end;

    [Test]
    procedure GetPaymentsMeansPayeeFinancialAcc_BankAcc()
    var
        CompanyInfo: Record "Company Information";
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        FinancialInstitutionBranchID: Text;
        FinancialInstitutionID: Text;
        FinancialInstitutionName: Text;
        FinancialInstitutionSchemeID: Text;
        PayeeFinancialAccountID: Text;
        PaymentMeansSchemeID: Text;
    begin
        // Setup for Bank Acc.
        Initialize();

        CompanyInfo.Get();
        CompanyInfo.IBAN := '';
        CompanyInfo."SWIFT Code" := LibraryUtility.GenerateGUID();
        CompanyInfo."Bank Account No." := LibraryUtility.GenerateGUID();
        CompanyInfo.Modify(false);

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansPayeeFinancialAcc(
          PayeeFinancialAccountID, PaymentMeansSchemeID, FinancialInstitutionBranchID, FinancialInstitutionID,
          FinancialInstitutionSchemeID, FinancialInstitutionName);

        // Verify
        Assert.AreEqual(CompanyInfo."Bank Account No.", PayeeFinancialAccountID, '');
        Assert.AreEqual('LOCAL', PaymentMeansSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Branch No.", FinancialInstitutionBranchID, '');
        Assert.AreEqual(CompanyInfo."SWIFT Code", FinancialInstitutionID, '');
        Assert.AreEqual('BIC', FinancialInstitutionSchemeID, '');
        Assert.AreEqual(CompanyInfo."Bank Name", FinancialInstitutionName, '');
    end;

    [Test]
    procedure GetPaymentMeansFinancialInstitutionAddr()
    var
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        AdditionalStreetName: Text;
        FinancialInstCountryIdCode: Text;
        FinancialInstCountryListID: Text;
        FinancialInstCountrySubentity: Text;
        FinancialInstitutionCityName: Text;
        FinancialInstitutionPostalZone: Text;
        FinancialInstitutionStreetName: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansFinancialInstitutionAddr(
          FinancialInstitutionStreetName, AdditionalStreetName, FinancialInstitutionCityName, FinancialInstitutionPostalZone,
          FinancialInstCountrySubentity, FinancialInstCountryIdCode, FinancialInstCountryListID);

        // Verify
        Assert.AreEqual('', FinancialInstitutionStreetName, '');
        Assert.AreEqual('', AdditionalStreetName, '');
        Assert.AreEqual('', FinancialInstitutionCityName, '');
        Assert.AreEqual('', FinancialInstitutionPostalZone, '');
        Assert.AreEqual('', FinancialInstCountrySubentity, '');
        Assert.AreEqual('', FinancialInstCountryIdCode, '');
        Assert.AreEqual('', FinancialInstCountryListID, '');
    end;

    [Test]
    procedure GetPaymentTermsInfo()
    var
        DummySalesHeader: Record "Sales Header";
        PEPPOLPaymentInfoProvider: Interface "PEPPOL Payment Info Provider";
        PaymentMeansCode: Text;
        PaymentMeansListID: Text;
        PaymentDueDate: Text;
        PaymentChannelCode: Text;
        PaymentID: Text;
        PrimaryAccountNumberID: Text;
        NetworkID: Text;
    begin
        // Setup
        Initialize();

        DummySalesHeader."Due Date" := LibraryRandom.RandDate(10);

        // Exercise
        PEPPOLPaymentInfoProvider := GetFormat();
        PEPPOLPaymentInfoProvider.GetPaymentMeansInfo(
          DummySalesHeader, PaymentMeansCode, PaymentMeansListID, PaymentDueDate, PaymentChannelCode,
          PaymentID, PrimaryAccountNumberID, NetworkID);
        // Verify
        Assert.AreEqual('31', PaymentMeansCode, '');
        Assert.AreEqual('UNCL4461', PaymentMeansListID, '');
        Assert.AreEqual(Format(DummySalesHeader."Due Date", 0, 9), PaymentDueDate, '');
        Assert.AreEqual('', PaymentChannelCode, '');
        Assert.AreEqual('', PaymentID, '');
        Assert.AreEqual('', PrimaryAccountNumberID, '');
        Assert.AreEqual('', NetworkID, '');
    end;

    [Test]
    procedure GetAllowanceChargeInfo()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        AllowanceChargeCurrencyID: Text;
        AllowanceChargeListID: Text;
        AllowanceChargeReason: Text;
        AllowanceChargeReasonCode: Text;
        AllowanceChargeTaxSchemeID: Text;
        Amount: Text;
        ChargeIndicator: Text;
        Percent: Text;
        TaxCategoryID: Text;
        TaxCategorySchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CustInvoiceDisc.Init();
        CustInvoiceDisc.Validate(Code, LibraryUtility.GenerateGUID());
        CustInvoiceDisc.Validate("Discount %", 10);
        CustInvoiceDisc.Insert(true);
        Cust.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);



        SalesLine.SetRecFilter();
        SalesLine.SetRange("Line No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        GetVATAmt(SalesLine, TempVATAmtLine);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetAllowanceChargeInfo(
          TempVATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID,
          AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID,
          Percent, AllowanceChargeTaxSchemeID);

        // Verify
        Assert.AreEqual('false', ChargeIndicator, 'ChargeIndicator has unexpected value.');
        Assert.AreEqual('104', AllowanceChargeReasonCode, 'AllowanceChargeReasonCode has unexpected value.');
        Assert.AreEqual('UNCL4465', AllowanceChargeListID, 'AllowanceChargeListID has unexpected value.');
        Assert.AreEqual('Invoice Discount Amount', AllowanceChargeReason, 'AllowanceChargeReason has unexpected value.');
        Assert.AreEqual(Format(TempVATAmtLine."Invoice Discount Amount", 0, 9), Amount, 'Amount has unexpected value.');
        Assert.AreEqual(LibraryERM.GetLCYCode(), AllowanceChargeCurrencyID, 'AllowanceChargeCurrencyID has unexpected value.');
        Assert.AreEqual(TempVATAmtLine."VAT Identifier", TaxCategoryID, 'TaxCategoryID has unexpected value.');
        Assert.AreEqual('', TaxCategorySchemeID, 'TaxCategorySchemeID has unexpected value.');
        Assert.AreEqual(Format(TempVATAmtLine."VAT %", 0, 9), Percent, 'Percent has unexpected value.');
        Assert.AreEqual('VAT', AllowanceChargeTaxSchemeID, 'AllowanceChargeTaxSchemeID has unexpected value.');
    end;

    [Test]
    procedure GetTaxExchangeRateInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        CalculationRate: Text;
        Date: Text;
        MathematicOperatorCode: Text;
        SourceCurrencyCode: Text;
        SourceCurrencyCodeListID: Text;
        TargetCurrencyCode: Text;
        TargetCurrencyCodeListID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        Cust.Validate("Currency Code", CreateCurrencyCode());
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxExchangeRateInfo(
          SalesHeader, SourceCurrencyCode, SourceCurrencyCodeListID, TargetCurrencyCode, TargetCurrencyCodeListID,
          CalculationRate, MathematicOperatorCode, Date);

        // Verify
        Assert.AreEqual(SalesHeader."Currency Code", SourceCurrencyCode, '');
        Assert.AreEqual('ISO4217', SourceCurrencyCodeListID, '');
        Assert.AreEqual(LibraryERM.GetLCYCode(), TargetCurrencyCode, '');
        Assert.AreEqual('ISO4217', TargetCurrencyCodeListID, '');
        Assert.AreEqual(Format(SalesHeader."Currency Factor", 0, 9), CalculationRate, '');
        Assert.AreEqual('Multiply', MathematicOperatorCode, '');
        Assert.AreEqual(Format(SalesHeader."Posting Date", 0, 9), Date, '');
    end;

    [Test]
    procedure GetTaxTotalInfo()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        TaxAmount: Text;
        TaxTotalCurrencyID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CustInvoiceDisc.Init();
        CustInvoiceDisc.Validate(Code, LibraryUtility.GenerateGUID());
        CustInvoiceDisc.Validate("Discount %", 10);
        CustInvoiceDisc.Insert(true);
        Cust.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesLine.SetRecFilter();
        SalesLine.SetRange("Line No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        GetVATAmt(SalesLine, TempVATAmtLine);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxTotalInfo(SalesHeader, TempVATAmtLine, TaxAmount, TaxTotalCurrencyID);

        // Verify
        Assert.AreEqual(Format(TempVATAmtLine."VAT Amount", 0, 9), TaxAmount, '');
        Assert.AreEqual(LibraryERM.GetLCYCode(), TaxTotalCurrencyID, '');
    end;

    [Test]
    procedure GetTaxTotalInfoLCYForLCYInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        TaxAmount: Text;
        TaxCurrencyID: Text;
        TaxTotalCurrencyID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389982] GetTaxTotalInfoLCY returns blank values for LCY sales invoice
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateItemWithPrice(Item, LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesHeader."No." := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);

        Assert.AreEqual('', TaxAmount, '');
        Assert.AreEqual('', TaxCurrencyID, '');
        Assert.AreEqual('', TaxTotalCurrencyID, '');
    end;

    [Test]
    procedure GetTaxTotalInfoLCYForFCYInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        TaxAmount: Text;
        TaxCurrencyID: Text;
        TaxTotalCurrencyID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389982] GetTaxTotalInfoLCY returns blank TaxCurrency and VAT Amount in FCY for FCY sales invoice
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateItemWithPrice(Item, LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Currency Code", CreateCurrencyCode());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesHeader."No." := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);

        VATEntry.SetRange("Document No.", SalesHeader."No.");
        VATEntry.FindFirst();
        Assert.AreEqual(Format(Abs(VATEntry.Amount), 0, 9), TaxAmount, 'TaxAmount');
        Assert.AreEqual('', TaxCurrencyID, '');
        Assert.AreEqual('', TaxTotalCurrencyID, '');
    end;

    [Test]
    procedure GetTaxTotalInfoLCYForCrMemoInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        TaxAmount: Text;
        TaxCurrencyID: Text;
        TaxTotalCurrencyID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389982] GetTaxTotalInfoLCY returns blank TaxCurrency and VAT Amount in FCY for FCY sales credit memo
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateItemWithPrice(Item, LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Currency Code", CreateCurrencyCode());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesHeader."No." := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);

        VATEntry.SetRange("Document No.", SalesHeader."No.");
        VATEntry.FindFirst();
        Assert.AreEqual(Format(Abs(VATEntry.Amount), 0, 9), TaxAmount, 'TaxAmount');
        Assert.AreEqual('', TaxCurrencyID, '');
        Assert.AreEqual('', TaxTotalCurrencyID, '');
    end;

    [Test]
    procedure GetTaxSubtotalInfo()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        schemeID: Text;
        SubtotalTaxAmount: Text;
        TaxableAmount: Text;
        TaxAmountCurrencyID: Text;
        TaxCategoryPercent: Text;
        TaxSubtotalCurrencyID: Text;
        TaxTotalTaxCategoryID: Text;
        TaxTotalTaxSchemeID: Text;
        TransactionCurrencyTaxAmount: Text;
        TransCurrTaxAmtCurrencyID: Text;
        ActualTaxableAmount: Decimal;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CustInvoiceDisc.Init();
        CustInvoiceDisc.Validate(Code, LibraryUtility.GenerateGUID());
        CustInvoiceDisc.Validate("Discount %", 10);
        CustInvoiceDisc.Insert(true);
        Cust.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesLine.SetRecFilter();
        SalesLine.SetRange("Line No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        GetVATAmt(SalesLine, TempVATAmtLine);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        PEPPOLTaxInfoProvider := GetFormat();
        PEPPOLTaxInfoProvider.GetTaxSubtotalInfo(
          TempVATAmtLine,
          SalesHeader,
          TaxableAmount,
          TaxAmountCurrencyID,
          SubtotalTaxAmount,
          TaxSubtotalCurrencyID,
          TransactionCurrencyTaxAmount,
          TransCurrTaxAmtCurrencyID,
          TaxTotalTaxCategoryID,
          schemeID,
          TaxCategoryPercent,
          TaxTotalTaxSchemeID);

        // Verify
        Evaluate(ActualTaxableAmount, TaxableAmount);
        Assert.AreEqual(TempVATAmtLine."VAT Base", ActualTaxableAmount, 'TaxableAmount has unexpected value.');
        Assert.AreEqual(LibraryERM.GetLCYCode(), TaxAmountCurrencyID, 'TaxAmountCurrencyID has unexpected value.');
        Assert.AreEqual(Format(TempVATAmtLine."VAT Amount", 0, 9), SubtotalTaxAmount, 'SubtotalTaxAmount has unexpected value.');
        Assert.AreEqual(LibraryERM.GetLCYCode(), TaxSubtotalCurrencyID, 'TaxSubtotalCurrencyID has unexpected value.');
        // Assert.AreEqual(FORMAT(tempVATAmtLine."Amount including vat",0,9),TransactionCurrencyTaxAmount,'TransactionCurrencyTaxAmount has unexpected value.');
        // Assert.AreEqual(LibraryERM.GetLCYCode(),TransCurrTaxAmtCurrencyID,'TransCurrTaxAmtCurrencyID has unexpected value.');
        Assert.AreEqual(TempVATAmtLine."VAT Identifier", TaxTotalTaxCategoryID, 'TaxTotalTaxCategoryID has unexpected value.');
        Assert.AreEqual('', schemeID, 'schemeID has unexpected value.'); // (TFS 388773)
        Assert.AreEqual(Format(TempVATAmtLine."VAT %", 0, 9), TaxCategoryPercent, 'TaxCategoryPercent has unexpected value.');
        Assert.AreEqual('VAT', TaxTotalTaxSchemeID, 'TaxTotalTaxSchemeID has unexpected value.');
    end;

    [Test]
    procedure GetTotals_DiffVATGroups()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmountLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 311001] TempVATAmountLines generated per each VAT Identifier
        Initialize();

        // [GIVEN] Sales Invoice
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);

        // [GIVEN] Two VAT Posting Setup with "VAT25" and "VAT10" Identifiers, Tax Category "O" and "S"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup2."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup2."Tax Category" := Format(LibraryRandom.RandIntInRange(10, 100));
        VATPostingSetup2.Modify(false);

        // [GIVEN] Two sales lines of VAT Posting Setup "VAT25" with Amount Incl. VAT = 110 and 120
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        VATPostingSetup1.Get(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup2."VAT %" := VATPostingSetup1."VAT %" + 1;
        VATPostingSetup2.Modify(false);
        // [GIVEN] Two  sales lines of VAT Posting Setup "VAT10" with Amount Incl. VAT = 30 and 40
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetTotals for the Sales Invoice
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        PEPPOLTaxInfoProvider := GetFormat();
        repeat
            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmountLine);
            TempVATAmountLine.TestField("VAT %", SalesLine."VAT %");
            TempVATAmountLine.TestField("VAT Identifier", Format(SalesLine."VAT %"));
        until SalesLine.Next() = 0;

        // [THEN] Two TempVATAmountLines generated for the Sales Invoice
        // [THEN] TempVATAmountLine "VAT25" has VAT % = 25, Tax Category = "O", Amount Incl. VAT = 230
        // [THEN] TempVATAmountLine "VAT10" has VAT % = 10, Tax Category = "S", Amount Incl. VAT = 70
        Assert.RecordCount(TempVATAmountLine, 2);
        VerifyVATAmountLine(TempVATAmountLine, SalesLine, VATPostingSetup1);
        VerifyVATAmountLine(TempVATAmountLine, SalesLine, VATPostingSetup2);
        VATPostingSetup2.Delete(false);
    end;

    [Test]
    procedure GetTotals_PositiveNegativeLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmountLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 340791] One TempVATAmountLines generated for the invoice with positive and negative lines of the same item
        Initialize();

        // [GIVEN] Item with Unit Price = 100 and VAT% = 25
        CreateGenericItem(Item);
        // [GIVEN] Sales Invoice with two lines of Quantity = 2 and Quantity = -1
        // [GIVEN] Document Amount Incl VAT = 125, Amount = 100
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -LibraryRandom.RandIntInRange(1, 3));

        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetTotals for the Sales Invoice
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        PEPPOLTaxInfoProvider := GetFormat();
        repeat
            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmountLine);
            TempVATAmountLine.TestField("VAT %", SalesLine."VAT %");
            TempVATAmountLine.TestField("VAT Identifier", Format(SalesLine."VAT %"));
        until SalesLine.Next() = 0;

        // [THEN] One TempVATAmountLine generated for the Sales Invoice
        // [THEN] TempVATAmountLine has VAT % = 25, Amount Incl. VAT = 125
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        Assert.RecordCount(TempVATAmountLine, 1);
        VerifyVATAmountLine(TempVATAmountLine, SalesLine, VATPostingSetup);
    end;

    [Test]
    procedure GetLegalMonetaryInfo()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Prices Excl. VAT] [UT]
        // [SCENARIO 292657] COD 1605 PEPPOLMgt.GetLegalMonetaryInfo() returns "LineExtensionAmount" = line amount excluding vat + invoice discount
        // [SCENARIO 292657] in case of "Prices Including VAT" = FALSE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = FALSE, , VAT % = 10
        // [GIVEN] "Unit Price" = 4000, "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Amount" = 3500, "Amount Including VAT" = 4375
        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetLegalMonetaryInfo()
        // [THEN] "LineExtensionAmount" = 4000
        // [THEN] "TaxExclusiveAmount" = 3500
        // [THEN] "TaxInclusiveAmount" = 4375
        // [THEN] "AllowanceTotalAmount" = 500
        // [THEN] "Unit Price" = 4000 (TFS ID 311001)
        InvoiceNo := CreatePostSalesInvoiceFCY(false);
        VerifyGetLegalMonetaryInfo(InvoiceNo);
        FindSalesInvoiceLine(SalesInvoiceLine, InvoiceNo);
        SalesLine.TransferFields(SalesInvoiceLine);
        VerifyGetLinePriceInfo(InvoiceNo, Format(SalesLine."Unit Price", 0, 9));
    end;

    [Test]
    procedure GetLegalMonetaryInfo_PricesInclVAT()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        InvoiceNo: Code[20];
        VATBaseIdx: Decimal;
    begin
        // [FEATURE] [Prices Incl. VAT] [UT]
        // [SCENARIO 292657] COD 1605 PEPPOLMgt.GetLegalMonetaryInfo() returns "LineExtensionAmount" = line amount excluding vat + invoice discount
        // [SCENARIO 292657] in case of "Prices Including VAT" = TRUE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = TRUE, VAT % = 10
        // [GIVEN] "Unit Price" = 5000, "Line Amount" = 5000, "Invoice Discount Amount" = 500, "Amount" = 3600, "Amount Including VAT" = 4500
        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetLegalMonetaryInfo()
        // [THEN] "LineExtensionAmount" = 4100
        // [THEN] "TaxExclusiveAmount" = 3600
        // [THEN] "TaxInclusiveAmount" = 4500
        // [THEN] "AllowanceTotalAmount" = 500
        // [THEN] "Unit Price" = 4000 (Item net price) (TFS ID 311001)
        InvoiceNo := CreatePostSalesInvoiceFCY(true);
        VerifyGetLegalMonetaryInfo(InvoiceNo);
        FindSalesInvoiceLine(SalesInvoiceLine, InvoiceNo);
        VATBaseIdx := 1 + SalesInvoiceLine."VAT %" / 100;
        VerifyGetLinePriceInfo(InvoiceNo, Format(Round(SalesInvoiceLine."Unit Price" / VATBaseIdx), 0, 9));
    end;

    [Test]
    procedure GetLineGeneralInfo()
    begin
        // [FEATURE] [Prices Excl. VAT] [UT]
        // [SCENARIO 292657] COD 1605 PEPPOLMgt.GetLineGeneralInfo() returns "LineExtensionAmount" = line amount excluding vat + invoice discount
        // [SCENARIO 292657] in case of "Prices Including VAT" = FALSE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = FALSE, "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Amount" = 3500, "Amount Including VAT" = 4375
        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetLegalMonetaryInfo()
        // [THEN] "LineExtensionAmount" = 4000
        // [THEN] "TaxExclusiveAmount" = 3500
        // [THEN] "TaxInclusiveAmount" = 4375
        // [THEN] "AllowanceTotalAmount" = 500
        VerifyGetLineGeneralInfo(CreatePostSalesInvoiceFCY(false));
    end;

    [Test]
    procedure GetLineGeneralInfo_PricesInclVAT()
    begin
        // [FEATURE] [Prices Incl. VAT] [UT]
        // [SCENARIO 292657] COD 1605 PEPPOLMgt.GetLineGeneralInfo() returns "LineExtensionAmount" = line amount excluding vat + invoice discount
        // [SCENARIO 292657] in case of "Prices Including VAT" = TRUE
        Initialize();

        // [GIVEN] Posted sales invoice with "Prices Including VAT" = TRUE, "Line Amount" = 5000, "Invoice Discount Amount" = 500, "Amount" = 3600, "Amount Including VAT" = 4500
        // [WHEN] Invoke COD 1605 PEPPOLMgt.GetLegalMonetaryInfo()
        // [THEN] "LineExtensionAmount" = 4100
        // [THEN] "TaxExclusiveAmount" = 3600
        // [THEN] "TaxInclusiveAmount" = 4500
        // [THEN] "AllowanceTotalAmount" = 500
        VerifyGetLineGeneralInfo(CreatePostSalesInvoiceFCY(true));
    end;

    [Test]
    procedure GetLineInvoicePeriodInfo()
    var
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        InvLineInvoicePeriodEndDate: Text;
        InvLineInvoicePeriodStartDate: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineInvoicePeriodInfo(InvLineInvoicePeriodStartDate, InvLineInvoicePeriodEndDate);

        // Verify
        Assert.AreEqual('', InvLineInvoicePeriodStartDate, '');
        Assert.AreEqual('', InvLineInvoicePeriodEndDate, '');
    end;

    [Test]
    procedure GetLineDeliveryInfo()
    var
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        InvoiceLineActualDeliveryDate: Text;
        InvoiceLineDeliveryID: Text;
        InvoiceLineDeliveryIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineDeliveryInfo(InvoiceLineActualDeliveryDate, InvoiceLineDeliveryID, InvoiceLineDeliveryIDSchemeID);

        // Verify
        Assert.AreEqual('', InvoiceLineActualDeliveryDate, '');
        Assert.AreEqual('', InvoiceLineDeliveryID, '');
        Assert.AreEqual('', InvoiceLineDeliveryIDSchemeID, '');
    end;

    [Test]
    procedure GetLineAllowanceChargeInfo()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        GenPostingSetup: Record "General Posting Setup";
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        InvLnAllowanceChargeAmount: Text;
        InvLnAllowanceChargeAmtCurrID: Text;
        InvLnAllowanceChargeIndicator: Text;
        InvLnAllowanceChargeReason: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CustInvoiceDisc.Init();
        CustInvoiceDisc.Validate(Code, LibraryUtility.GenerateGUID());
        CustInvoiceDisc.Validate("Discount %", 10);
        CustInvoiceDisc.Insert(true);
        Cust.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Cust.Modify(true);

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(9, 2));
        SalesLine.Modify(true);

        SalesLine.SetRecFilter();
        SalesLine.SetRange("Line No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Ensure that Sales Invoice Discount Account is set to a valid G/L Account
        GenPostingSetup.ModifyAll("Sales Inv. Disc. Account", LibraryERM.CreateGLAccountNo());

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineAllowanceChargeInfo(
          SalesLine, SalesHeader, InvLnAllowanceChargeIndicator, InvLnAllowanceChargeReason, InvLnAllowanceChargeAmount,
          InvLnAllowanceChargeAmtCurrID);

        // Verify - invoice discount is not present at line level
        Assert.AreEqual('false', InvLnAllowanceChargeIndicator, '');
        Assert.AreEqual(Format(InvoiceDiscAmtTxt), InvLnAllowanceChargeReason, '');
        Assert.AreEqual(Format(SalesLine."Line Discount Amount", 0, 9), InvLnAllowanceChargeAmount, '');
        Assert.AreEqual(LibraryERM.GetLCYCode(), InvLnAllowanceChargeAmtCurrID, '');
    end;

    [Test]
    procedure GetLineTaxTotal()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        currencyID: Text;
        InvoiceLineTaxAmount: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineTaxTotal(SalesLine, SalesHeader, InvoiceLineTaxAmount, currencyID);

        // Verify
        Assert.AreEqual(Format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, 9), InvoiceLineTaxAmount, '');
        Assert.AreEqual(LibraryERM.GetLCYCode(), currencyID, '');
    end;

    [Test]
    procedure GetLineItemInfoAsItem()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        Description: Text;
        Name: Text;
        OriginCountryIdCode: Text;
        OriginCountryIdCodeListID: Text;
        SellersItemIdentificationID: Text;
        StandardItemIdentificationID: Text;
        StdItemIdIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemInfo(
          SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID,
          OriginCountryIdCode, OriginCountryIdCodeListID);

        // Verify
        Assert.AreEqual(SalesInvoiceLine.Description, Name, '');
        Assert.AreEqual(SalesInvoiceLine."Description 2", Description, '');
        Assert.AreEqual(SalesInvoiceLine."No.", SellersItemIdentificationID, '');
        Assert.AreEqual(Item.GTIN, StandardItemIdentificationID, '');
        Assert.AreEqual('0160', StdItemIdIDSchemeID, '');
        Assert.AreEqual('', OriginCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', OriginCountryIdCodeListID, '');
    end;

    [Test]
    procedure GetLineItemInfoAsResource()
    var
        Cust: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        Description: Text;
        Name: Text;
        OriginCountryIdCode: Text;
        OriginCountryIdCodeListID: Text;
        SellersItemIdentificationID: Text;
        StandardItemIdentificationID: Text;
        StdItemIdIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);

        LibraryResource.CreateResource(Resource, Cust."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", 1);
        SalesLine."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        SalesLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        SalesLine.Modify(false);

        Clear(VATPostingSetup);
        VATPostingSetup.ModifyAll(Blocked, false);
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemInfo(
          SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID,
          OriginCountryIdCode, OriginCountryIdCodeListID);

        // Verify
        Assert.AreEqual(SalesInvoiceLine.Description, Name, '');
        Assert.AreEqual(SalesInvoiceLine."Description 2", Description, '');
        Assert.AreEqual('', SellersItemIdentificationID, '');
        Assert.AreEqual('', StandardItemIdentificationID, '');
        Assert.AreEqual('', StdItemIdIDSchemeID, '');
        Assert.AreEqual('', OriginCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', OriginCountryIdCodeListID, '');
    end;

    [Test]
    procedure GetLineItemInfoAsGLLine()
    var
        Cust: Record Customer;
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        Description: Text;
        Name: Text;
        OriginCountryIdCode: Text;
        OriginCountryIdCodeListID: Text;
        SellersItemIdentificationID: Text;
        StandardItemIdentificationID: Text;
        StdItemIdIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Modify(false);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        SalesLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        SalesLine.Modify(false);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemInfo(
          SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID,
          OriginCountryIdCode, OriginCountryIdCodeListID);

        // Verify
        Assert.AreEqual(SalesInvoiceLine.Description, Name, '');
        Assert.AreEqual(SalesInvoiceLine."Description 2", Description, '');
        Assert.AreEqual('', SellersItemIdentificationID, '');
        Assert.AreEqual('', StandardItemIdentificationID, '');
        Assert.AreEqual('', StdItemIdIDSchemeID, '');
        Assert.AreEqual('', OriginCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', OriginCountryIdCodeListID, '');
    end;

    [Test]
    procedure GetLineItemInfoAsItemCharge()
    var
        Cust: Record Customer;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        Description: Text;
        Name: Text;
        OriginCountryIdCode: Text;
        OriginCountryIdCodeListID: Text;
        SellersItemIdentificationID: Text;
        StandardItemIdentificationID: Text;
        StdItemIdIDSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        LibraryInvt.CreateItem(Item);
        LibraryInvt.CreateItemCharge(ItemCharge);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLine."Line Amount" := LibraryRandom.RandInt(100);
        SalesLine.Amount := LibraryRandom.RandInt(100);
        SalesLine.Modify(false);

        LibraryInvt.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", Item."No.");

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemInfo(
          SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID,
          OriginCountryIdCode, OriginCountryIdCodeListID);

        // Verify
        Assert.AreEqual(SalesInvoiceLine.Description, Name, '');
        Assert.AreEqual(SalesInvoiceLine."Description 2", Description, '');
        Assert.AreEqual('', SellersItemIdentificationID, '');
        Assert.AreEqual('', StandardItemIdentificationID, '');
        Assert.AreEqual('', StdItemIdIDSchemeID, '');
        Assert.AreEqual('', OriginCountryIdCode, '');
        Assert.AreEqual('ISO3166-1:Alpha2', OriginCountryIdCodeListID, '');
    end;

    [Test]
    procedure GetLineItemCommodityClassificationInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        CommodityCode: Text;
        CommodityCodeListID: Text;
        ItemClassificationCode: Text;
        ItemClassificationCodeListID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemCommodityClassificationInfo(
          CommodityCode, CommodityCodeListID, ItemClassificationCode, ItemClassificationCodeListID);

        // Verify
        Assert.AreEqual('', CommodityCode, '');
        Assert.AreEqual('', CommodityCodeListID, '');
        Assert.AreEqual('', ItemClassificationCode, '');
        Assert.AreEqual('', ItemClassificationCodeListID, '');
    end;

    [Test]
    procedure GetLineItemClassifiedTaxCategory()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        ClassifiedTaxCategoryID: Text;
        ClassifiedTaxCategorySchemeID: Text;
        InvoiceLineTaxPercent: Text;
        ItemSchemeID: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineItemClassifiedTaxCategory(
          SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);

        // Verify
        VATPostingSetup.Get(Cust."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        Assert.AreEqual(VATPostingSetup."Tax Category", ClassifiedTaxCategoryID, '');
        Assert.AreEqual('', ItemSchemeID, ''); // (TFS 388773)
        Assert.AreEqual(Format(SalesInvoiceLine."VAT %", 0, 9), InvoiceLineTaxPercent, '');
        Assert.AreEqual('VAT', ClassifiedTaxCategorySchemeID, '');
    end;

    [Test]
    procedure GetLineAdditionalItemPropertyInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        AdditionalItemPropertyName: Text;
        AdditionalItemPropertyValue: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");

        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineAdditionalItemPropertyInfo(SalesLine, AdditionalItemPropertyName, AdditionalItemPropertyValue);

        // Verify
        Assert.AreEqual('', AdditionalItemPropertyName, '');
        Assert.AreEqual('', AdditionalItemPropertyValue, '');
    end;

    [Test]
    procedure GetLinePriceInfo()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        SalesInvoiceNo: Code[20];
        BaseQuantity: Text;
        InvLinePriceAmountCurrencyID: Text;
        InvoiceLinePriceAmount: Text;
        UnitCode: Text;
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceLine.Get(SalesInvoiceNo, SalesLine."Line No.");
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure");
        SalesLine.TransferFields(SalesInvoiceLine);

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLinePriceInfo(SalesLine, SalesHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);

        // Verify
        Assert.AreEqual(Format(SalesInvoiceLine."Line Amount", 0, 9), InvoiceLinePriceAmount, '');
        Assert.AreEqual(LibraryERM.GetLCYCode(), InvLinePriceAmountCurrencyID, '');
        Assert.AreEqual(Format(SalesInvoiceLine."Quantity (Base)", 0, 9), BaseQuantity, '');
        Assert.AreEqual(UnitOfMeasure."International Standard Code", UnitCode, '');
    end;

    [Test]
    procedure GetLinePriceAllowanceChargeInfo()
    var
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        PriceAllowanceAmountCurrencyID: Text;
        PriceAllowanceChargeAmount: Text;
        PriceAllowanceChargeBaseAmount: Text;
        PriceAllowChargeBaseAmtCurrID: Text;
        PriceChargeIndicator: Text;
    begin
        // Setup
        Initialize();

        // Exercise
        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLinePriceAllowanceChargeInfo(
          PriceChargeIndicator, PriceAllowanceChargeAmount, PriceAllowanceAmountCurrencyID, PriceAllowanceChargeBaseAmount,
          PriceAllowChargeBaseAmtCurrID);

        // Verify
        Assert.AreEqual('', PriceChargeIndicator, '');
        Assert.AreEqual('', PriceAllowanceChargeAmount, '');
        Assert.AreEqual('', PriceAllowanceAmountCurrencyID, '');
        Assert.AreEqual('', PriceAllowanceChargeBaseAmount, '');
        Assert.AreEqual('', PriceAllowChargeBaseAmtCurrID, '');
    end;

    [Test]
    procedure GetCrMemoBillingReferenceInfoNoAppliesToDoc()
    var
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        InvoiceDocRefID: Text;
        InvoiceDocRefIssueDate: Text;
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreateGenericItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetCrMemoBillingReferenceInfo(
          SalesCrMemoHeader,
          InvoiceDocRefID,
          InvoiceDocRefIssueDate);

        // Verify
        Assert.AreEqual('', InvoiceDocRefID, '');
        Assert.AreEqual('', InvoiceDocRefIssueDate, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GetCrMemoBillingReferenceInfoWithItemAppliesToDoc()
    var
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InvoiceSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        InvoiceDocRefID: Text;
        InvoiceDocRefIssueDate: Text;
    begin
        // Setup
        Initialize();

        CreateGenericItem(Item);

        CreateGenericSalesHeader(InvoiceSalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        LibrarySales.CreateSalesLine(SalesLine, InvoiceSalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(InvoiceSalesHeader, false, false));
        AttachAppliesToDocToHeaderFromPostedInvoice(SalesHeader, SalesInvoiceHeader);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetCrMemoBillingReferenceInfo(
          SalesCrMemoHeader,
          InvoiceDocRefID,
          InvoiceDocRefIssueDate);

        // Verify
        Assert.AreEqual(SalesInvoiceHeader."No.", InvoiceDocRefID, '');
        Assert.AreEqual(Format(SalesInvoiceHeader."Posting Date", 0, 9), InvoiceDocRefIssueDate, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GetCrMemoBillingReferenceInfoWithOtherAppliesToDoc()
    var
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        InvoiceDocRefID: Text;
        InvoiceDocRefIssueDate: Text;
    begin
        // Setup
        Initialize();

        CreateGenericItem(Item);

        CreateGenericSalesHeader(SalesHeader1, SalesHeader1."Document Type"::"Credit Memo");
        CreateGenericSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader1, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Item, Item."No.", 1);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader2, false, false));
        AttachAppliesToDocToHeaderFromPostedCreditMemo(SalesHeader1, SalesCrMemoHeader);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader1, false, false));

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetCrMemoBillingReferenceInfo(
          SalesCrMemoHeader,
          InvoiceDocRefID,
          InvoiceDocRefIssueDate);

        // Verify
        Assert.AreEqual('', InvoiceDocRefID, '');
        Assert.AreEqual('', InvoiceDocRefIssueDate, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GetCrMemoBillingReferenceInfoWithInvalidAppliesToDoc()
    var
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InvoiceSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PEPPOLDocumentInfoProvider: Interface "PEPPOL Document Info Provider";
        InvoiceDocRefID: Text;
        InvoiceDocRefIssueDate: Text;
    begin
        // Setup
        Initialize();

        CreateGenericItem(Item);

        CreateGenericSalesHeader(InvoiceSalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        LibrarySales.CreateSalesLine(SalesLine, InvoiceSalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(InvoiceSalesHeader, false, false));
        AttachAppliesToDocToHeaderFromPostedInvoice(SalesHeader, SalesInvoiceHeader);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        SalesInvoiceHeader.Delete(false); // Applies-to-doc no longer exists

        // Exercise
        PEPPOLDocumentInfoProvider := GetFormat();
        PEPPOLDocumentInfoProvider.GetCrMemoBillingReferenceInfo(
          SalesCrMemoHeader,
          InvoiceDocRefID,
          InvoiceDocRefIssueDate);

        // Verify
        Assert.AreEqual('', InvoiceDocRefID, '');
        Assert.AreEqual('', InvoiceDocRefIssueDate, '');
    end;

    [Test]
    procedure TestPeppolValidationSalesInvoiceLine()
    var
        Item1: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item1);
        CreateGenericItem(Item2);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item1."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", 2);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // Error is thrown if validation fails
    end;

    [Test]
    procedure TestPeppolValidationSalesCrMemoLine()
    var
        Item1: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreateGenericItem(Item1);
        CreateGenericItem(Item2);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item1."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", 2);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // Error is thrown if validation fails
    end;

    [Test]
    procedure TestPeppolValidationSalesInvoiceLineNoUnitOfMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit of Measure Code", '');
        SalesLine.Modify(true);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);
        Assert.ExpectedError(StrSubstNo(NoUnitOfMeasureErr, SalesHeader."No."));
    end;

    [Test]
    procedure TestPeppolValidationSalesInvoiceLineNoItemDescription()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Description := '';
        SalesLine.Modify(false);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);
        Assert.ExpectedError(NoItemDescriptionErr);
    end;

    [Test]
    procedure TestPeppolValidationSalesInvoiceLineNoInternationalStandardCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Setup
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        UnitOfMeasure.Validate("International Standard Code", '');
        UnitOfMeasure.Modify(true);

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);
        Assert.ExpectedError(StrSubstNo(NoInternationalStandardCodeErr, UnitOfMeasure.Code));
    end;

    [Test]
    procedure ValidateSalesInvoicePageContainFields()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        SalesInvoice: TestPage "Sales Invoice";
        SalesInvoiceSubform: TestPage "Sales Invoice Subform";
    begin
        // Ensure the required fields for PEPPOL validation
        // can be entered on the sales invoice page

        SalesInvoice.OpenNew();
        SalesInvoiceSubform.OpenNew();

        AssertVisibility(SalesInvoice."Currency Code".Visible(), 'Sales Invoice.Currency Code');

        AssertVisibility(SalesInvoice."Your Reference".Visible(), 'Sales Invoice.Your Reference');
        AssertVisibility(SalesInvoice."Shipment Date".Visible(), 'Sales Invoice.Shipment Date');

        AssertVisibility(SalesInvoice."Due Date".Visible(), 'Sales Invoice.Due Date');

        if not ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            AssertVisibility(SalesInvoiceSubform.Type.Visible(), 'Sales Line.Type');
        AssertVisibility(SalesInvoiceSubform."No.".Visible(), 'Sales Line.To.');
        AssertVisibility(SalesInvoiceSubform.Quantity.Visible(), 'Sales Line.Quantity');
        AssertVisibility(SalesInvoiceSubform."Unit of Measure Code".Visible(), 'Sales Line.Unit of Measure Code');
    end;

    [Test]
    procedure ValidateSalesCreditMemoPageContainFields()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        SalesCrMemoSubform: TestPage "Sales Cr. Memo Subform";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Ensure the required fields for PEPPOL validation
        // can be entered on the sales credit memo page

        SalesCreditMemo.OpenNew();
        SalesCrMemoSubform.OpenNew();

        AssertVisibility(SalesCreditMemo."Currency Code".Visible(), 'Sales Credit Memo.Currency Code');

        AssertVisibility(SalesCreditMemo."Bill-to Name".Visible(), 'Sales Credit Memo.Bill-to Name');
        AssertVisibility(SalesCreditMemo."Your Reference".Visible(), 'Sales Credit Memo.Your Reference');
        AssertVisibility(SalesCreditMemo."Shipment Date".Visible(), 'Sales Credit Memo.Shipment Date');
        AssertVisibility(SalesCreditMemo."Due Date".Visible(), 'Sales Credit Memo.Due Date');

        if not ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            AssertVisibility(SalesCrMemoSubform.Type.Visible(), 'Sales Credit Memo Line.Type');
        AssertVisibility(SalesCrMemoSubform."No.".Visible(), 'Sales Credit Memo Line.No.');
        AssertVisibility(SalesCrMemoSubform.Quantity.Visible(), 'Sales Credit Memo Line.Quantity');
        AssertVisibility(SalesCrMemoSubform."Unit of Measure Code".Visible(), 'Sales Credit Memo Line.Unit of Measure');

        AssertVisibility(SalesCreditMemo."Applies-to Doc. Type".Visible(), 'Sales Credit Memo.Applies-to Doc. Type');
        AssertVisibility(SalesCreditMemo."Applies-to Doc. No.".Visible(), 'Sales Credit Memo.Applies-to Doc. No.');
        AssertVisibility(SalesCreditMemo."External Document No.".Visible(), 'Sales Credit Memo.External Document No.');
    end;

    [Test]
    procedure ValidatePeppolContainsFieldsOnResponsibilityCenterCard()
    var
        ResponsibilityCenterCard: TestPage "Responsibility Center Card";
    begin
        // [SCENARIO] Ensure the required fields for PEPPOL validation can be entered on Responsibility Center Card page

        ResponsibilityCenterCard.OpenNew();
        AssertVisibility(ResponsibilityCenterCard.Name.Visible(), 'Resp Center.Name');
        AssertVisibility(ResponsibilityCenterCard.Address.Visible(), 'Resp Center.Address');
        AssertVisibility(ResponsibilityCenterCard."Address 2".Visible(), 'Resp Center.Address 2');
        AssertVisibility(ResponsibilityCenterCard."Post Code".Visible(), 'Resp Center.Post Code');
        AssertVisibility(ResponsibilityCenterCard.City.Visible(), 'Resp Center.City');
        AssertVisibility(ResponsibilityCenterCard."Country/Region Code".Visible(), 'Respt Center.Country/Region Code');
        ResponsibilityCenterCard.Close();
    end;

    [Test]
    procedure ValidatePeppolContainsFieldsOnCompanyInformation()
    var
        CompanyInformationPage: TestPage "Company Information";
    begin
        // [SCENARIO] Ensure the required fields for PEPPOL validation can be entered on Company Information page

        CompanyInformationPage.OpenEdit();
        AssertVisibility(CompanyInformationPage.Name.Visible(), 'Company Info.Name');
        AssertVisibility(CompanyInformationPage.Address.Visible(), 'Company Info.Address');
        AssertVisibility(CompanyInformationPage."Address 2".Visible(), 'Company Info.Address 2');
        AssertVisibility(CompanyInformationPage."Post Code".Visible(), 'Company Info.Post Code');
        AssertVisibility(CompanyInformationPage.City.Visible(), 'Company Info.City');
        AssertVisibility(CompanyInformationPage."Country/Region Code".Visible(), 'Company Info.Country/Region Code');

        AssertVisibility(CompanyInformationPage.GLN.Visible(), 'Company Info.GLN');
        AssertVisibility(CompanyInformationPage."Use GLN in Electronic Document".Visible(), 'Company Info.Use GLN in Electronic Document');
        AssertVisibility(CompanyInformationPage."VAT Registration No.".Visible(), 'Company Info.VAT Registration No.');

        AssertVisibility(CompanyInformationPage.IBAN.Visible(), 'Company Info.IBAN');
        AssertVisibility(CompanyInformationPage."Bank Account No.".Visible(), 'Company Info.Bank Account No.');
        AssertVisibility(CompanyInformationPage."Bank Branch No.".Visible(), 'Company Info.Bank Branch No.');
        CompanyInformationPage.Close();
    end;

    [Test]
    procedure ValidatePeppolContainsFieldsOnCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] Ensure the required fields for PEPPOL validation can be entered on Customer Card page

        CustomerCard.OpenEdit();
        AssertVisibility(CustomerCard.Name.Visible(), 'Customer Card.Name');
        AssertVisibility(CustomerCard.Address.Visible(), 'Customer Card.Address');
        AssertVisibility(CustomerCard."Address 2".Visible(), 'Customer Card.Address 2');
        AssertVisibility(CustomerCard."Post Code".Visible(), 'Customer Card.Post Code');
        AssertVisibility(CustomerCard.City.Visible(), 'Customer Card.City');
        AssertVisibility(CustomerCard."Country/Region Code".Visible(), 'Customer Card.Country/Region Code');
        AssertVisibility(CustomerCard.GLN.Visible(), 'Customer Card.GLN');
        AssertVisibility(CustomerCard."Use GLN in Electronic Document".Visible(), 'Customer Card.Use GLN in Electronic Document');
        AssertVisibility(CustomerCard."VAT Registration No.".Visible(), 'Customer Card."VAT Registration No."');
        CustomerCard.Close();
    end;

    [Test]
    procedure ValidatePeppolContainsFieldsOnCustomerBankAccountCard()
    var
        CustomerBankAccountCard: TestPage "Customer Bank Account Card";
    begin
        // [SCENARIO] Ensure the required fields for PEPPOL validation can be entered on Customer Bank Account Card page

        CustomerBankAccountCard.OpenNew();
        AssertVisibility(CustomerBankAccountCard."Bank Account No.".Visible(), 'Customer Bank Acc.Bank Account No.');
        AssertVisibility(CustomerBankAccountCard."Bank Branch No.".Visible(), 'Customer Bank Acc.Bank Branch No.');
        AssertVisibility(CustomerBankAccountCard.IBAN.Visible(), 'Customer Bank Acc.IBAN');
        CustomerBankAccountCard.Close();
    end;

    [Test]
    procedure ValidatePeppolContainsFieldsOnUnitsofMeasure()
    var
        UnitsofMeasure: TestPage "Units of Measure";
    begin
        // [SCENARIO] Ensure the required fields for PEPPOL validation can be entered on Units of Measure page

        UnitsofMeasure.OpenNew();
        AssertVisibility(UnitsofMeasure.Code.Visible(), 'Unit of Measure.Code');
        AssertVisibility(UnitsofMeasure."International Standard Code".Visible(), 'Unit of measure.International Standard Code');
        UnitsofMeasure.Close();
    end;

    [Test]
    procedure PEPPOL_XMLExport_TaxCurrencyCode_DocumentTypeCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XML: Text;
    begin
        // [FEATURE] [XML] [Invoice]
        // [SCENARIO 205106] Export PEPPOL does not generate cbc:TaxCurrencyCode and cbc:DocumentTypeCode elements.

        Initialize();
        UpdateCompanySwiftCode();

        // [GIVEN] Posted sales invoice for the customer
        SalesInvoiceHeader.Get(CreatePostSalesInvoice());

        // [WHEN] Send the invoice electronically with PEPPOL format
        SalesInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesInvoiceHeader, GetPEPPOLFormat());

        // [THEN] cbc:TaxCurrencyCode and cbc:DocumentTypeCode elements are not exported
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        LibraryXMLRead.VerifyNodeValue('cbc:ProfileID', 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
        LibraryXMLRead.VerifyNodeAbsence('cbc:TaxCurrencyCode');
        LibraryXMLRead.VerifyNodeAbsence('cac:AdditionalDocumentReference/cbc:DocumentTypeCode');

        // [THEN] cbc:InvoicedQuantity and cbc:BaseQuantity elements do not have unitCodeListID attribute
        LibraryXMLRead.VerifyAttributeAbsence('cac:InvoiceLine/cbc:InvoicedQuantity', 'unitCodeListID');
        LibraryXMLRead.VerifyAttributeAbsence('cac:InvoiceLine/cac:Price/cbc:BaseQuantity', 'unitCodeListID');
    end;

    local procedure InitLibraryXML(XML: Text; Namespace: Text)
    begin
        LibraryXMLRead.InitializeWithText(XML, Namespace);
        LibraryXMLRead.SetDefaultNamespaceUsage(false);
        LibraryXMLRead.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXMLRead.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        LibraryXMLRead.AddAdditionalNamespace('ccts', 'urn:un:unece:uncefact:documentation:2');
        LibraryXMLRead.AddAdditionalNamespace('qdt', 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2');
        LibraryXMLRead.AddAdditionalNamespace('udt', 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2');
    end;

    [Test]
    procedure PEPPOLMgtGetGLNDeliveryInfoUT()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277023] PEPPOLMgt.GetGLNDeliveryInfo() returns ActualDeliveryDate = "Shipment Date", DeliveryID = Ship-to Address.GLN, DeliveryIDSchemeID = '0088'

        // Blanked "Shipment Date" and blanked "Ship-to Code"
        DummySalesHeader.Init();
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, '', '', '');

        // "Shipment Date" and blanked "Ship-to Code"
        DummySalesHeader."Shipment Date" := LibraryRandom.RandDate(100);
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, Format(DummySalesHeader."Shipment Date", 0, 9), '', '');

        // "Shipment Date" and Ship-to Address without GLN
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        DummySalesHeader."Sell-to Customer No." := Customer."No.";
        DummySalesHeader."Ship-to Code" := ShipToAddress.Code;
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, Format(DummySalesHeader."Shipment Date", 0, 9), '', '');

        // Blanked "Shipment Date" and Ship-to Address without GLN
        DummySalesHeader."Shipment Date" := 0D;
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, '', '', '');

        // Blanked "Shipment Date" and Ship-to Address with GLN
        ShipToAddress.GLN := LibraryUtility.GenerateGUID();
        ShipToAddress.Modify(false);
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, '', ShipToAddress.GLN, '0088');

        // "Shipment Date" and Ship-to Address with GLN
        DummySalesHeader."Shipment Date" := LibraryRandom.RandDate(100);
        VerifyPEPPOLMgtGetGLNDeliveryInfo(DummySalesHeader, Format(DummySalesHeader."Shipment Date", 0, 9), ShipToAddress.GLN, '0088');
    end;

    [Test]
    procedure PEPPOLMgtGetGLNForHeaderUTWithBlankSellToCustomer()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 289768] PEPPOLMgt.GetGLNForHeader() returns '' when "Sell-to Customer No." is empty

        DummySalesHeader.Init();
        VerifyPEPPOLMgtGetGLNForHeader(DummySalesHeader, '');
    end;

    [Test]
    procedure PEPPOLMgtGetGLNForHeaderUTWithSellToCustomer()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 289768] PEPPOLMgt.GetGLNForHeader() returns Customer.GLN when "Sell-to Customer No." is filled and "Ship-to Code" is blank

        DummySalesHeader.Init();
        CreateCustomerWithGLN(Customer);
        DummySalesHeader."Sell-to Customer No." := Customer."No.";
        VerifyPEPPOLMgtGetGLNForHeader(DummySalesHeader, Customer.GLN);
    end;

    [Test]
    procedure PEPPOLMgtGetGLNForHeaderUTWithSellToCustomerAndShipToCode()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 289768] PEPPOLMgt.GetGLNForHeader() returns Ship-to Address.GLN when it's not empty and both "Ship-to Code" and "Sell-to Customer No." are filled

        DummySalesHeader.Init();
        CreateCustomerWithGLN(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.GLN := CreateValidGLN();
        ShipToAddress.Modify(false);
        DummySalesHeader."Ship-to Code" := ShipToAddress.Code;
        DummySalesHeader."Sell-to Customer No." := Customer."No.";
        VerifyPEPPOLMgtGetGLNForHeader(DummySalesHeader, ShipToAddress.GLN);
    end;

    [Test]
    procedure PEPPOLMgtGetGLNForHeaderUTWithBlankShipToAddressGLN()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 289768] PEPPOLMgt.GetGLNForHeader() returns Customer.GLN when Ship-to Address.GLN is empty and both "Ship-to Code" and "Sell-to Customer No." are filled

        DummySalesHeader.Init();
        CreateCustomerWithGLN(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        DummySalesHeader."Ship-to Code" := ShipToAddress.Code;
        DummySalesHeader."Sell-to Customer No." := Customer."No.";
        VerifyPEPPOLMgtGetGLNForHeader(DummySalesHeader, Customer.GLN);
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesInvoice_ShipToAddress()
    var
        Customer: Record Customer;
        DummySalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipToAddress: Record "Ship-to Address";
        XML: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 289768] PEPPOL Sales Invoice Delivery info (ActualDeliveryDate, Delivery ID) when Ship-to Code if filled in
        Initialize();

        // [GIVEN] Posted Sales Invoice ("Shipment Date" = 18-07-2018, Ship-to Address.GLN = 12345) and "Ship-to Code" is filled in
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithShipToAddress(CreateCustomerWithAddressAndGLN(), DummySalesHeader."Document Type"::Invoice));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        ShipToAddress.Get(Customer."No.", SalesInvoiceHeader."Ship-to Code");

        // [WHEN] Export PEPPOL format
        SalesInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesInvoiceHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018", "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        LibraryXMLRead.VerifyNodeValue('cbc:ProfileID', 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesInvoiceHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', ShipToAddress.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesInvoice_noShipToCode()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XML: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 277023] PEPPOL Sales Invoice Delivery info (ActualDeliveryDate, Delivery ID)
        Initialize();

        // [GIVEN] Posted Sales Invoice ("Shipment Date" = 18-07-2018, Customer.GLN = 12345) and no "Ship-to Code"
        SalesInvoiceHeader.Get(CreatePostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Export PEPPOL format
        SalesInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesInvoiceHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018", "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesInvoiceHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesInvoice_BlankedGLN()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XML: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 277023] PEPPOL Sales Invoice Delivery info (ActualDeliveryDate, blanked Delivery ID)
        Initialize();

        // [GIVEN] Posted Sales Invoice ("Shipment Date" = 18-07-2018, Customer.GLN = "") and no "Ship-to Code"
        SalesInvoiceHeader.Get(CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::Invoice));

        // [WHEN] Export PEPPOL format
        SalesInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesInvoiceHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesInvoiceHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeAbsence('cac:Delivery/cac:DeliveryLocation/cbc:ID');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesCrMemo_ShipToAddress()
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DummySalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
        XML: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 289768] PEPPOL Sales Credit Memo Delivery info (ActualDeliveryDate, Delivery ID) when Ship-to Address is filled in
        Initialize();

        // [GIVEN] Posted Sales Credit Memo ("Shipment Date" = 18-07-2018, Ship-to Address.GLN = 12345) with a "Ship-to Code"
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithShipToAddress(CreateCustomerWithAddressAndGLN(), DummySalesHeader."Document Type"::"Credit Memo"));
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        ShipToAddress.Get(Customer."No.", SalesCrMemoHeader."Ship-to Code");

        // [WHEN] Export PEPPOL format
        SalesCrMemoHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesCrMemoHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018", "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesCrMemoHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', ShipToAddress.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesCrMemo_noShipToCode()
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XML: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 277023] PEPPOL Sales Credit Memo Delivery info (ActualDeliveryDate, Delivery ID)
        Initialize();

        // [GIVEN] Posted Sales Credit Memo ("Shipment Date" = 18-07-2018, Customer.GLN = 12345) and no "Ship-to Code"
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo());
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");

        // [WHEN] Export PEPPOL format
        SalesCrMemoHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesCrMemoHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018", "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesCrMemoHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_SalesCrMemo_BlankedGLN()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        XML: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 277023] PEPPOL Sales Credit Memo Delivery info (ActualDeliveryDate, blanked Delivery ID)
        Initialize();

        // [GIVEN] Posted Sales Invoice ("Shipment Date" = 18-07-2018, Customer.GLN = "") and no "Ship-to Code"
        SalesCrMemoHeader.Get(CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::"Credit Memo"));

        // [WHEN] Export PEPPOL format
        SalesCrMemoHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesCrMemoHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ActualDeliveryDate" = "18-07-2018"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cbc:ActualDeliveryDate', Format(SalesCrMemoHeader."Shipment Date", 0, 9));
        LibraryXMLRead.VerifyNodeAbsence('cac:Delivery/cac:DeliveryLocation/cbc:ID');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_ServiceInvoice()
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        XML: Text;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 277023] PEPPOL Service Invoice Delivery info (ActualDeliveryDate, Delivery ID)
        Initialize();

        // [GIVEN] Posted Service Invoice (Customer.GLN = 12345)
        CreatePostServiceInvoice(ServiceInvoiceHeader);
        Customer.Get(ServiceInvoiceHeader."Customer No.");

        // [WHEN] Export PEPPOL format
        ServiceInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(ServiceInvoiceHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        LibraryXMLRead.VerifyNodeAbsence('cac:Delivery/cbc:ActualDeliveryDate'); // No "Shipment Date" for Service Invoice
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    procedure PEPPOL_XMLExport_DeliveryInfo_ServiceCrMemo()
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        XML: Text;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 277023] PEPPOL Service Credit Memo Delivery info (ActualDeliveryDate, Delivery ID)
        Initialize();

        // [GIVEN] Posted Service Credit Memo (Customer.GLN = 12345)
        CreatePostServiceCrMemo(ServiceCrMemoHeader);
        Customer.Get(ServiceCrMemoHeader."Customer No.");

        // [WHEN] Export PEPPOL format
        ServiceCrMemoHeader.SetRecFilter();
        XML := PEPPOLXMLExport(ServiceCrMemoHeader, GetPEPPOLFormat());

        // [THEN] "Delivery" tag has been exported with "ID" = "12345", "ID/schemeID" = "0088"
        InitLibraryXML(XML, 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');
        LibraryXMLRead.VerifyNodeAbsence('cac:Delivery/cbc:ActualDeliveryDate'); // No "Shipment Date" for Service Credit Memo
        LibraryXMLRead.VerifyNodeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValue('cac:Delivery/cac:DeliveryLocation/cbc:ID', 'schemeID', '0088');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseOnUnitPrice')]
    procedure TestPeppolValidationSalesLineWithNegativeUnitPriceConfirmFalse()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342393] Confirm false on PEPPOL validation for Sales Invoice with negative price
        Initialize();

        // [GIVEN] Sales Invoice where the line has Unit Price = -1000.
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Validate("Unit Price", -LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        // [WHEN] Validate the sales invoice with No on confirmation for 'Do you want to continue?'
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // [THEN] The process is stopped with error
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrueOnUnitPrice')]
    procedure TestPeppolValidationSalesLineWithNegativeUnitPriceConfirmTrue()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342393] Confirm true on PEPPOL validation for Sales Invoice with negative price
        Initialize();

        // [GIVEN] Sales Invoice where the line has Unit Price = -1000.
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateGenericItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Validate("Unit Price", -LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        // [WHEN] Validate the sales invoice with Yes on confirmation for 'Do you want to continue?'
        CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // [THEN] Validation is finished sucessfully
    end;

    [Test]
    procedure TestPeppolValidationISOCodeOnCompanyCountry()
    var
        CompanyInformationLocal: Record "Company Information";
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 362281] Error when validate document and ISO code in not specified in Country/Region of Company
        Initialize();

        // [GIVEN] Company information has Country/Region with ISO Code not specified
        CompanyInformationLocal.Get();
        CountryRegion.Code := Format(LibraryRandom.RandIntInRange(10, 99));
        CountryRegion.Insert(false);
        CompanyInformationLocal."Country/Region Code" := CountryRegion.Code;
        CompanyInformationLocal.Modify(false);

        // [GIVEN] Sales Invoice is created
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run PEPPOL validation for the Sales Invoice
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // [THEN] Error appeared that 'ISO Code must have a value'
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, CountryRegion.FieldCaption("ISO Code")));
    end;

    [Test]
    procedure TestPeppolValidationISOCodeOnSalesDocCountry()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 362281] Error when validate document and ISO code in not specified in Country/Region of sales document
        Initialize();

        // [GIVEN] Country/Region with ISO Code not specified
        CountryRegion.Code := Format(LibraryRandom.RandIntInRange(10, 99));
        CountryRegion.Insert(false);

        // [GIVEN] Sales Invoice is created with the Country/Resion above
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        SalesHeader.Modify(false);

        // [WHEN] Run PEPPOL validation for the Sales Invoice
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);

        // [THEN] Error appeared that 'ISO Code must have a value'
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, CountryRegion.FieldCaption("ISO Code")));
    end;

    [Test]
    procedure PEPPOLValidation_LongCountryRegion()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376447] PEPPOL Validation gives no errors for document with Country/Region Code having lenth not equal 2
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateCountryRegion(CountryRegion);
        SalesHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        SalesHeader.Modify(false);
        CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);
    end;

    [Test]
    procedure PEPPOLValidation_WrongLengthISOCode()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376447] PEPPOL Validation gives error for document where ISO Code has lenth not equal 2
        Initialize();

        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."ISO Code" := '1';
        CountryRegion.Modify(false);
        SalesHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        SalesHeader.Modify(false);
        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL30 Sales Validation", SalesHeader);
        Assert.ExpectedError('ISO Code should be 2 characters long');
        Assert.ExpectedErrorCode('TableErrorStr');
    end;

    [Test]
    procedure PEPPOLValidationSalesInvoiceWhenSalesLineTypeCommentAndDescriptionBlank()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        XML: Text;
    begin
        // [SCENARIO 487175] Blank Description in Sales Invoice Comment Line leads to an error message during PEPPOL transmission.
        Initialize();

        // [GIVEN] Create a Sales Header with document type Invoice.
        CreateGenericSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Create a Item.
        CreateGenericItem(Item);

        // [GIVEN] Create a Sales Line with Type Item.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Create another sales line with the comment and assign the description as empty.
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::" ", '', 0);
        SalesLine2.Validate(Description, '');
        SalesLine2.Modify(true);

        // [GIVEN] Post Sales invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Send the Invoice Electronically in PEPPOL format..
        SalesInvoiceHeader.SetRecFilter();
        XML := PEPPOLXMLExport(SalesInvoiceHeader, GetPEPPOLFormat());

        // [VERIFY] Invoice Successfully send the electronically in PEPPOL transmission.
        Assert.IsTrue(XML <> '', InvoiceElectronicallySendPEPPOLFormatTxt);
    end;

    [Test]
    procedure GetAccountingCustomerPartyTaxSchemeBIS30()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // [SCENARIO] PEPPOLMgt.GetAccountingCustomerPartyTaxSchemeBIS30 returns correct values for Customer with PEPPOL identifier and empty tax scheme ID.
        Initialize();

        // [GIVEN] Customer with PEPPOL identifier and country/region code
        Cust.Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());
        AddCustPEPPOLIdentifier(Cust."No.");
        Cust.Modify(false);
        // [GIVEN] Posted sales document
        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        GetVatAmtWithTaxCategory(SalesLine, TempVATAmtLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Excute GetAccountingCustomerPartyTaxSchemeBIS30
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyTaxSchemeBIS30(
            SalesHeader,
            CustPartyTaxSchemeCompanyID,
            CustPartyTaxSchemeCompIDSchID,
            CustTaxSchemeID,
            TempVATAmtLine);

        // [THEN] Correct values are returned
        Assert.AreEqual(Cust.FormatVATRegistrationNo(Cust.GetVATRegistrationNo(), Cust."Country/Region Code"), CustPartyTaxSchemeCompanyID, 'Cutomer Party Tax Scheme Company ID should match VAT Registration No.');
        Assert.AreEqual('', CustPartyTaxSchemeCompIDSchID, 'Company ID''s Scheme ID should be empty.');
        Assert.AreEqual('VAT', CustTaxSchemeID, 'Wrong Tax Scheme ID.');
    end;

    [Test]
    procedure GetAccountingCustomerPartyTaxSchemeBIS30WithTaxSchemeIDWithOTaxCategory()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLPartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // [SCENARIO] PEPPOLMgt.GetAccountingCustomerPartyTaxSchemeBIS30 returns correct values for Customer with PEPPOL identifier and tax scheme ID with O tax category.
        Initialize();

        // [GIVEN] Customer with PEPPOL identifier and country/region code
        Cust.Get(LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo());
        AddCustPEPPOLIdentifier(Cust."No.");
        Cust.Modify(false);
        // [GIVEN] Posted sales document
        CreateItemWithPrice(Item, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        GetVatAmtWithTaxCategory(SalesLine, TempVATAmtLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] VAT Amount Line with O tax category
        TempVATAmtLine.Findfirst();
        TempVATAmtLine."Tax Category" := 'O';
        TempVATAmtLine.Modify(false);

        // [WHEN] Excute GetAccountingCustomerPartyTaxSchemeBIS30
        PEPPOLPartyInfoProvider := GetFormat();
        PEPPOLPartyInfoProvider.GetAccountingCustomerPartyTaxSchemeBIS30(
            SalesHeader,
            CustPartyTaxSchemeCompanyID,
            CustPartyTaxSchemeCompIDSchID,
            CustTaxSchemeID,
            TempVATAmtLine);

        // [THEN] Correct values are returned
        Assert.AreEqual('', CustPartyTaxSchemeCompanyID, 'Cutomer Party Tax Scheme Company ID should be empty for Tax Category O.');
        Assert.AreEqual('', CustPartyTaxSchemeCompIDSchID, 'Company ID''s Scheme ID should be empty.');
        Assert.AreEqual('', CustTaxSchemeID, 'Tax Scheme ID should be empty for Tax Category O.');
    end;

    var
    local procedure Initialize()
    var
        CountryRegion: Record "Country/Region";
        GenPostingSetup: Record "General Posting Setup";
        GLSetup: Record "General Ledger Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"PEPPOL30 Management Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"PEPPOL30 Management Tests");

        LibraryERM.FindCountryRegion(CountryRegion);

        CompanyInformation.Get();
        CompanyInformation.Name := 'PEPPOL Test Company';
        CompanyInformation.Address := '1 PEPPOL Street';
        CompanyInformation.City := 'London';
        CompanyInformation."Post Code" := 'E1 8QS';
        CompanyInformation.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInformation.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInformation.Validate("Bank Branch No.", '1234');
        CompanyInformation."Country/Region Code" := CountryRegion.Code;

        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");

        CompanyInformation.Modify(true);
        GLSetup.GetRecordOnce();
        GLSetup."VAT Reporting Date Usage" := GLSetup."VAT Reporting Date Usage"::Disabled;
        GLSetup.Modify(false);


        AddCompPEPPOLIdentifier();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();
        UpdateElectronicDocumentFormatSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        ConfigureVATPostingSetup();

        GenPostingSetup.ModifyAll("Sales Inv. Disc. Account", LibraryERM.CreateGLAccountNo());
        GenPostingSetup.ModifyAll("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"PEPPOL30 Management Tests");
    end;

    local procedure AddCustPEPPOLIdentifier(CustNo: Code[20])
    var
        Cust: Record Customer;
    begin
        Cust.Get(CustNo);
        Cust.Validate(GLN, '1234567891231');
        Cust.Modify(true);
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithGLN(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(GLN, CreateValidGLN());
        Customer.Modify(false);
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."ISO Code" :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion."ISO Code")),
            1, MaxStrLen(CountryRegion."ISO Code"));
        CountryRegion.Modify(false);
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify(false);
    end;

    local procedure CreateItem(var Item: Record Item): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInvt.CreateItemWithoutVAT(Item);

        VATPostingSetup.SetFilter("VAT %", '<>%1', 0);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGenericSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        CountryRegion: Record "Country/Region";
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        AddCustPEPPOLIdentifier(Cust."No.");

        LibraryERM.FindCountryRegion(CountryRegion);

        Cust.Validate(Address, LibraryUtility.GenerateRandomCode(Cust.FieldNo(Address), DATABASE::Customer));
        Cust.Validate("Country/Region Code", CountryRegion.Code);
        Cust.Validate(City, LibraryUtility.GenerateRandomCode(Cust.FieldNo(City), DATABASE::Customer));
        Cust.Validate("Post Code", LibraryUtility.GenerateRandomCode(Cust.FieldNo("Post Code"), DATABASE::Customer));
        Cust."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Cust.Validate(GLN, '1234567890128');
        Cust.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Cust."No.");
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), DATABASE::"Sales Header"));

        if DocumentType = SalesHeader."Document Type"::"Credit Memo" then
            SalesHeader.Validate("Shipment Date", WorkDate());

        SalesHeader.CopySellToAddressToShipToAddress();
        SalesHeader.Modify(true);
    end;

    local procedure CreateGenericItem(var Item: Record Item)
    var
        ItemUOM: Record "Item Unit of Measure";
        UOM: Record "Unit of Measure";
        LibraryUtilityLocal: Codeunit "Library - Utility";
        QtyPerUnit: Integer;
    begin
        QtyPerUnit := LibraryRandom.RandInt(10);

        LibraryInvt.CreateUnitOfMeasureCode(UOM);
        UOM.Validate("International Standard Code",
          LibraryUtilityLocal.GenerateRandomCode(UOM.FieldNo("International Standard Code"), DATABASE::"Unit of Measure"));
        UOM.Modify(true);

        CreateItemWithPrice(Item, LibraryRandom.RandInt(10));

        LibraryInvt.CreateItemUnitOfMeasure(ItemUOM, Item."No.", UOM.Code, QtyPerUnit);

        Item.Validate("Sales Unit of Measure", UOM.Code);
        Item.Modify(true);
    end;

    local procedure CreateElectronicDocumentFormatSetup(NewCode: Code[20]; NewUsage: Enum "Electronic Document Format Usage"; NewCodeunitID: Integer)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := NewCode;
        ElectronicDocumentFormat.Usage := NewUsage;
        ElectronicDocumentFormat."Codeunit ID" := NewCodeunitID;
        if ElectronicDocumentFormat.Insert(false) then;
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure AddCompPEPPOLIdentifier()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate(GLN, '1234567891231');
        CompanyInfo.Modify(true);
    end;

    local procedure AttachAppliesToDocToHeaderFromPostedCreditMemo(var SalesHeader: Record "Sales Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.Positive := true;
            CustLedgerEntry.Modify(false);
        end;

        SalesHeader.Validate("Sell-to Customer No.", SalesCrMemoHeader."Sell-to Customer No.");
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::"Credit Memo");
        SalesHeader.Validate("Applies-to Doc. No.", SalesCrMemoHeader."No.");
        SalesHeader.Modify(false);
    end;

    local procedure AttachAppliesToDocToHeaderFromPostedInvoice(var SalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesHeader.Validate("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        SalesHeader.Modify(false);
    end;

#pragma warning disable AL0432
    local procedure GetVATAmt(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
#pragma warning restore AL0432
    begin
        VATAmtLine.Init();
        VATAmtLine."VAT Identifier" := SalesLine."Tax Category";
        VATAmtLine."VAT Calculation Type" := SalesLine."VAT Calculation Type";
        VATAmtLine."Tax Group Code" := SalesLine."Tax Group Code";
        VATAmtLine."VAT %" := SalesLine."VAT %";
        VATAmtLine."VAT Base" := SalesLine.Amount;
        VATAmtLine."Amount Including VAT" := SalesLine."Amount Including VAT";
        VATAmtLine."Line Amount" := SalesLine."Line Amount";
        if SalesLine."Allow Invoice Disc." then
            VATAmtLine."Inv. Disc. Base Amount" := SalesLine."Line Amount";
        VATAmtLine."Invoice Discount Amount" := SalesLine."Inv. Discount Amount";
        VATAmtLine.InsertLine();
    end;

#pragma warning disable AL0432
    local procedure GetVatAmtWithTaxCategory(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
#pragma warning restore AL0432
    var
        VatPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        GetVATAmt(SalesLine, VATAmtLine);
        VATAmtLine."Tax Category" := VATPostingSetup."Tax Category";
        VATAmtLine.Modify(false);
    end;

    local procedure AssertVisibility(IsVisible: Boolean; Name: Text)
    begin
        Assert.IsTrue(IsVisible, 'Control at ' + Name + ' is not visible');
    end;

    local procedure CreatePostSalesInvoice(): Code[20]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CreatePostSalesDoc(CreateCustomerWithAddressAndGLN(), DummySalesHeader."Document Type"::Invoice));
    end;

    local procedure CreatePostSalesCrMemo(): Code[20]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CreatePostSalesDoc(CreateCustomerWithAddressAndGLN(), DummySalesHeader."Document Type"::"Credit Memo"));
    end;

    local procedure CreatePostSalesDoc(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), DATABASE::"Sales Header"));
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesHeader.CopySellToAddressToShipToAddress();
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesDocWithShipToAddress(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateShipToAddressWithGLNForCustomer(ShipToAddress, CustomerNo);
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), DATABASE::"Sales Header"));
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.CopySellToAddressToShipToAddress();
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));

        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesInvoiceFCY(PricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        AddCustPEPPOLIdentifier(Customer."No.");

        Customer.Validate("Currency Code", CreateCurrencyCode());
        Customer.Modify(true);

        CreateItemWithPrice(Item, LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Inv. Discount Amount", Round(Item."Unit Price" / 3));
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateValidGLN(): Code[13]
    var
        CheckDigit: Text;
        FirstPart: Text;
    begin
        FirstPart := LibraryUtility.GenerateRandomNumericText(12);
        CheckDigit := Format(StrCheckSum(FirstPart, '131313131313'));
        exit(CopyStr(FirstPart + CheckDigit, 1, 13));
    end;

    local procedure CreatePostServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        DummyServiceHeader: Record "Service Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", CreatePostServiceDoc(DummyServiceHeader."Document Type"::Invoice));
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure CreatePostServiceCrMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        DummyServiceHeader: Record "Service Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", CreatePostServiceDoc(DummyServiceHeader."Document Type"::"Credit Memo"));
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure CreatePostServiceDoc(DocumentType: Enum "Service Document Type"): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServMgtSetup: Record "Service Mgt. Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate."Posting No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalTemplate.Modify(false);
        ServMgtSetup.GetRecordOnce();
        ServMgtSetup."Serv. Inv. Template Name" := GenJournalTemplate.Name;
        ServMgtSetup."Serv. Cr. Memo Templ. Name" := GenJournalTemplate.Name;
        ServMgtSetup.Modify(false);

        LibrarySales.CreateCustomerWithAddress(Customer);
        AddCustPEPPOLIdentifier(Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Due Date", LibraryRandom.RandDate(10));
        ServiceHeader.SetShipToAddress(ServiceHeader.Name, '', ServiceHeader.Address, ServiceHeader."Address 2",
        ServiceHeader.City, ServiceHeader."Post Code", ServiceHeader.County, ServiceHeader."Country/Region Code");
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateShipToAddressWithGLNForCustomer(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        Customer.Get(CustomerNo);
        ShipToAddress.Validate(GLN, CreateValidGLN());
        ShipToAddress.Validate(Address, Customer.Address);
        ShipToAddress.Validate("Address 2", Customer."Address 2");
        ShipToAddress.Validate("Country/Region Code", Customer."Country/Region Code");
        ShipToAddress.Validate(City, Customer.City);
        ShipToAddress.Validate("Post Code", Customer."Post Code");
        ShipToAddress.Validate(County, Customer.County);
        ShipToAddress.Modify(false);
    end;

    local procedure CreateCustomerWithAddressAndGLN(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        AddCustPEPPOLIdentifier(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithAddressAndVATRegNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Modify(false);
        exit(Customer."No.");
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; InvoiceNo: Code[20]);
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure GetPEPPOLFormat(): Code[20]
    begin
        exit('PEPPOL30');
    end;

    local procedure GetFormat(): Enum "PEPPOL 3.0 Format";
    var
        Peppol30Setup: Record "PEPPOL 3.0 Setup";
    begin
        Peppol30Setup.GetSetup();
        exit(Peppol30Setup."PEPPOL 3.0 Sales Format");
    end;

    local procedure PEPPOLXMLExport(DocumentVariant: Variant; FormatCode: Code[20]) Data: Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        Instream: InStream;
    begin
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, FormatCode);
        TempBlob.CreateInStream(Instream);
        Instream.Read(Data);
    end;

    local procedure UpdateCompanySwiftCode()
    var
        CompanyInformationLocal: Record "Company Information";
    begin
        CompanyInformationLocal.Get();
        CompanyInformationLocal.Validate("SWIFT Code", Format(LibraryRandom.RandIntInRange(1000000, 9999999)));
        CompanyInformationLocal.Modify(true);
    end;

    local procedure UpdateElectronicDocumentFormatSetup()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        CreateElectronicDocumentFormatSetup(
          GetPEPPOLFormat(), ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"Exp. Sales Inv. PEPPOL30");
        CreateElectronicDocumentFormatSetup(
          GetPEPPOLFormat(), ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"Exp. Sales CrM. PEPPOL30");
        CreateElectronicDocumentFormatSetup(
          GetPEPPOLFormat(), ElectronicDocumentFormat.Usage::"Service Invoice", CODEUNIT::"Exp. Serv.Inv. PEPPOL30");
        CreateElectronicDocumentFormatSetup(
          GetPEPPOLFormat(), ElectronicDocumentFormat.Usage::"Service Credit Memo", CODEUNIT::"Exp. Serv.CrM. PEPPOL30");
    end;

    local procedure VerifyPEPPOLMgtGetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; ExpectedActualDeliveryDate: Text; ExpectedDeliveryID: Text; ExpectedDeliveryIDSchemeID: Text)
    var
        PEPPOLDeliveryInfoProvider: Interface "PEPPOL Delivery Info Provider";
        ActualDeliveryDate: Text;
        DeliveryID: Text;
        DeliveryIDSchemeID: Text;
    begin
        PEPPOLDeliveryInfoProvider := GetFormat();
        PEPPOLDeliveryInfoProvider.GetGLNDeliveryInfo(SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
        Assert.AreEqual(ExpectedActualDeliveryDate, ActualDeliveryDate, 'ActualDeliveryDate');
        Assert.AreEqual(ExpectedDeliveryID, DeliveryID, 'DeliveryID');
        Assert.AreEqual(ExpectedDeliveryIDSchemeID, DeliveryIDSchemeID, 'DeliveryIDSchemeID');
    end;

    local procedure VerifyPEPPOLMgtGetGLNForHeader(SalesHeader: Record "Sales Header"; ExpectedGLN: Code[13])
    var
        PEPPOLDeliveryInfoProvider: Interface "PEPPOL Delivery Info Provider";
        ActualGLN: Code[13];
    begin
        PEPPOLDeliveryInfoProvider := GetFormat();
        ActualGLN := PEPPOLDeliveryInfoProvider.GetGLNForHeader(SalesHeader);
        Assert.AreEqual(ExpectedGLN, ActualGLN, 'Incorrect GLN');
    end;

    local procedure VerifyGetLegalMonetaryInfo(PostedInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        TempSalesLineInvRounding: Record "Sales Line" temporary;
#pragma warning disable AL0432
        TempVATAmtLine: Record "VAT Amount Line" temporary;
#pragma warning restore AL0432
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        AllowanceTotalAmount: Text;
        AllowanceTotalAmountCurrencyID: Text;
        ChargeTotalAmount: Text;
        ChargeTotalAmountCurrencyID: Text;
        LegalMonetaryTotalCurrencyID: Text;
        LineExtensionAmount: Text;
        PayableAmount: Text;
        PayableAmountCurrencyID: Text;
        PayableRndingAmountCurrencyID: Text;
        PayableRoundingAmount: Text;
        PrepaidAmount: Text;
        PrepaidCurrencyID: Text;
        TaxExclusiveAmount: Text;
        TaxExclusiveAmountCurrencyID: Text;
        TaxInclusiveAmount: Text;
        TaxInclusiveAmountCurrencyID: Text;
    begin
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesLine.TransferFields(SalesInvoiceLine);
        SalesLine.TestField("VAT %");
        SalesLine.TestField("Inv. Discount Amount");
        GetVATAmt(SalesLine, TempVATAmtLine);

        PEPPOLMonetaryInfoProvider := GetFormat();
        PEPPOLMonetaryInfoProvider.GetLegalMonetaryInfo(
          SalesHeader,
          TempSalesLineInvRounding,
          TempVATAmtLine,
          LineExtensionAmount,
          LegalMonetaryTotalCurrencyID,
          TaxExclusiveAmount,
          TaxExclusiveAmountCurrencyID,
          TaxInclusiveAmount,
          TaxInclusiveAmountCurrencyID,
          AllowanceTotalAmount,
          AllowanceTotalAmountCurrencyID,
          ChargeTotalAmount,
          ChargeTotalAmountCurrencyID,
          PrepaidAmount,
          PrepaidCurrencyID,
          PayableRoundingAmount,
          PayableRndingAmountCurrencyID,
          PayableAmount,
          PayableAmountCurrencyID);

        TempVATAmtLine.Reset();
        TempVATAmtLine.CalcSums("Line Amount", "VAT Base", "Amount Including VAT", "Invoice Discount Amount");

        Assert.AreEqual(
          Format(Round(TempVATAmtLine."VAT Base", 0.01) + Round(TempVATAmtLine."Invoice Discount Amount", 0.01), 0, 9),
          LineExtensionAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", LegalMonetaryTotalCurrencyID, '');
        Assert.AreEqual(Format(Round(TempVATAmtLine."VAT Base", 0.01), 0, 9), TaxExclusiveAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", TaxExclusiveAmountCurrencyID, '');
        Assert.AreEqual(Format(Round(TempVATAmtLine."Amount Including VAT", 0.01, '>'), 0, 9), TaxInclusiveAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", TaxInclusiveAmountCurrencyID, '');
        Assert.AreEqual('', ChargeTotalAmount, '');
        Assert.AreEqual(Format(Round(TempVATAmtLine."Invoice Discount Amount", 0.01), 0, 9), AllowanceTotalAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", AllowanceTotalAmountCurrencyID, '');
        Assert.AreEqual('0.00', PrepaidAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", PrepaidCurrencyID, '');
        Assert.AreEqual(
          Format(
            TempVATAmtLine."Amount Including VAT" - Round(TempVATAmtLine."Amount Including VAT", 0.01), 0, 9),
          PayableRoundingAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", PayableRndingAmountCurrencyID, '');
        Assert.AreEqual(Format(Round(TempVATAmtLine."Amount Including VAT", 0.01), 0, 9), PayableAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", PayableAmountCurrencyID, '');
    end;

    local procedure VerifyGetLinePriceInfo(PostedInvoiceNo: Code[20]; ExpectedLinePrice: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        BaseQuantity: Text;
        InvLinePriceAmountCurrencyID: Text;
        InvoiceLinePriceAmount: Text;
        UnitCode: Text;
    begin
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesLine.TransferFields(SalesInvoiceLine);

        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLinePriceInfo(SalesLine, SalesHeader, InvoiceLinePriceAmount, InvLinePriceAmountCurrencyID, BaseQuantity, UnitCode);
        Assert.AreEqual(ExpectedLinePrice, InvoiceLinePriceAmount, '');
    end;

    local procedure VerifyGetLineGeneralInfo(PostedInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        PEPPOLLineInfoProvider: Interface "PEPPOL Line Info Provider";
        InvoicedQuantity: Text;
        InvoiceLineAccountingCost: Text;
        InvoiceLineExtensionAmount: Text;
        InvoiceLineID: Text;
        InvoiceLineNote: Text;
        LineExtensionAmountCurrencyID: Text;
        unitCode: Text;
        unitCodeListID: Text;
        SalesInvoiceLineLineAmount: Decimal;
    begin
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesLine.TransferFields(SalesInvoiceLine);
        SalesLine.TestField("VAT %");
        SalesLine.TestField("Inv. Discount Amount");
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure");

        PEPPOLLineInfoProvider := GetFormat();
        PEPPOLLineInfoProvider.GetLineGeneralInfo(
          SalesLine, SalesHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity,
          InvoiceLineExtensionAmount, LineExtensionAmountCurrencyID, InvoiceLineAccountingCost);
        PEPPOLLineInfoProvider.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);

        Assert.AreEqual(Format(SalesInvoiceLine."Line No.", 0, 9), InvoiceLineID, '');
        Assert.AreEqual(Format(SalesInvoiceLine.Type), InvoiceLineNote, '');
        Assert.AreEqual(Format(SalesInvoiceLine.Quantity, 0, 9), InvoicedQuantity, '');
        Assert.AreEqual(UnitOfMeasure."International Standard Code", unitCode, '');
        Assert.AreEqual('UNECERec20', unitCodeListID, '');
        SalesInvoiceLineLineAmount := SalesInvoiceLine."Line Amount";
        Assert.AreEqual(Format(SalesInvoiceLineLineAmount, 0, 9), InvoiceLineExtensionAmount, '');
        Assert.AreEqual(SalesHeader."Currency Code", LineExtensionAmountCurrencyID, '');
        Assert.AreEqual('', InvoiceLineAccountingCost, '');
    end;

#pragma warning disable AL0432
    local procedure VerifyVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
#pragma warning restore AL0432
    begin
        VATAmountLine.SetRange("VAT Identifier", Format(VATPostingSetup."VAT %"));
        VATAmountLine.FindFirst();
        SalesLine.SetRange("VAT Identifier", VATPostingSetup."VAT Identifier");
        SalesLine.CalcSums(Amount, "Amount Including VAT");

        VATAmountLine.TestField("VAT %", VATPostingSetup."VAT %");
        VATAmountLine.TestField("Tax Category", VATPostingSetup."Tax Category");
        VATAmountLine.TestField("VAT Base", SalesLine.Amount);
        VATAmountLine.TestField("Amount Including VAT", SalesLine."Amount Including VAT");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrueOnUnitPrice(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(NegativeUnitPriceErr, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalseOnUnitPrice(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(NegativeUnitPriceErr, Question);
        Reply := false;
    end;
}

