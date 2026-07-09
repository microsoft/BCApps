// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.SE.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Peppol;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 148165 "PEPPOL SE BIS Billing Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PEPPOL] [BIS Billing] [SE]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        InvoiceNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;

    [Test]
    procedure GetAccountingSupplierPartyInfo_VATRegNo_SE()
    var
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] SE supplier EndpointID must carry the 10-digit organisation number under scheme 0007, not the full VAT.
        Initialize();

        // [GIVEN] Company Information in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601'
        SetupSECompany(SetupSECountryRegion(GetSEOrgNoSchemeID()));

        // [WHEN] Get Accounting Supplier Party Info (BIS) through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingSupplierPartyInfoBIS(SupplierEndpointID, SupplierSchemeID, SupplierName);

        // [THEN] EndpointID is the 10-digit organisation number under schemeID '0007'
        Assert.AreEqual(GetExpectedSEOrgNo(), SupplierEndpointID, '');
        Assert.AreEqual(GetSEOrgNoSchemeID(), SupplierSchemeID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyInfo_VATRegNo_SE()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustomerEndpointID: Text;
        CustomerSchemeID: Text;
        CustomerPartyIdentificationID: Text;
        CustomerPartyIDSchemeID: Text;
        CustomerName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] SE customer EndpointID must carry the 10-digit organisation number under scheme 0007, not the full VAT.
        Initialize();

        // [GIVEN] Customer in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601'
        CreateSECustomerForUnitTest(Customer);
        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Validate("VAT Registration No.", Customer."VAT Registration No.");

        // [WHEN] Get Accounting Customer Party Info (BIS) through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingCustomerPartyInfoBIS(
          SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName);

        // [THEN] EndpointID is the 10-digit organisation number under schemeID '0007'
        Assert.AreEqual(GetExpectedSEOrgNo(), CustomerEndpointID, '');
        Assert.AreEqual(GetSEOrgNoSchemeID(), CustomerSchemeID, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyLegalEntity_VATRegNo_SE()
    var
        CompanyInformation: Record "Company Information";
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        PartyLegalEntityRegName: Text;
        PartyLegalEntityCompanyID: Text;
        PartyLegalEntitySchemeID: Text;
        SupplierRegAddrCityName: Text;
        SupplierRegAddrCountryIdCode: Text;
        SupplRegAddrCountryIdListId: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] SE supplier PartyLegalEntity CompanyID must be the 10-digit organisation number.
        Initialize();

        // [GIVEN] Company Information in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601'
        SetupSECompany(SetupSECountryRegion(GetSEOrgNoSchemeID()));
        CompanyInformation.Get();

        // [WHEN] Get Accounting Supplier Party Legal Entity (BIS) through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingSupplierPartyLegalEntityBIS(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName,
          SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);

        // [THEN] CompanyID is the 10-digit organisation number; schemeID stays empty (non-DK BIS legal entity, unchanged)
        Assert.AreEqual(CompanyInformation.Name, PartyLegalEntityRegName, '');
        Assert.AreEqual(GetExpectedSEOrgNo(), PartyLegalEntityCompanyID, '');
        Assert.AreEqual('', PartyLegalEntitySchemeID, '');
    end;

    [Test]
    procedure GetAccountingCustomerPartyLegalEntity_VATRegNo_SE()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CustPartyLegalEntityRegName: Text;
        CustPartyLegalEntityCompanyID: Text;
        CustPartyLegalEntityIDSchemeID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] SE customer PartyLegalEntity CompanyID must be the 10-digit organisation number.
        Initialize();

        // [GIVEN] Customer in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601'
        CreateSECustomerForUnitTest(Customer);
        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Validate("VAT Registration No.", Customer."VAT Registration No.");

        // [WHEN] Get Accounting Customer Party Legal Entity (BIS) through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingCustomerPartyLegalEntityBIS(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);

        // [THEN] CompanyID is the 10-digit organisation number; schemeID stays empty (non-DK BIS legal entity, unchanged)
        Assert.AreEqual(Customer.Name, CustPartyLegalEntityRegName, '');
        Assert.AreEqual(GetExpectedSEOrgNo(), CustPartyLegalEntityCompanyID, '');
        Assert.AreEqual('', CustPartyLegalEntityIDSchemeID, '');
    end;

    [Test]
    procedure GetAccountingSupplierPartyInfo_VATScheme9955_SE()
    var
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        SupplierEndpointID: Text;
        SupplierSchemeID: Text;
        SupplierName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] An SE party registered under EAS 9955 (SE:VAT) must keep the full VAT in EndpointID, not be stripped to the org number.
        Initialize();

        // [GIVEN] Company Information in SE but VAT Scheme '9955' (SE:VAT) with "VAT Registration No." = 'SE733078715601'
        SetupSECompany(SetupSECountryRegion(GetSEVATSchemeID()));

        // [WHEN] Get Accounting Supplier Party Info (BIS) through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingSupplierPartyInfoBIS(SupplierEndpointID, SupplierSchemeID, SupplierName);

        // [THEN] EndpointID keeps the full VAT (scheme 9955 expects the VAT, not the organisation number)
        Assert.AreEqual(GetSEVATSchemeID(), SupplierSchemeID, '');
        Assert.AreNotEqual(GetExpectedSEOrgNo(), SupplierEndpointID, 'VAT must not be stripped to the organisation number when the scheme is 9955.');
        Assert.IsTrue(StrPos(SupplierEndpointID, '733078715601') > 0, 'EndpointID must retain the full Swedish VAT digits under scheme 9955.');
    end;

    [Test]
    procedure GetAccountingSupplierPartyTaxScheme_VATRegNo_SE()
    var
        PartyInfoProvider: Interface "PEPPOL Party Info Provider";
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] SE PartyTaxScheme CompanyID must keep the full VAT (BT-31), not be stripped to the organisation number.
        Initialize();

        // [GIVEN] Company Information in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601'
        SetupSECompany(SetupSECountryRegion(GetSEOrgNoSchemeID()));

        // [WHEN] Get Accounting Supplier Party Tax Scheme through the SE format
        PartyInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - SE Sales";
        PartyInfoProvider.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);

        // [THEN] CompanyID keeps the full VAT, not the stripped organisation number
        Assert.AreNotEqual(GetExpectedSEOrgNo(), CompanyID, 'PartyTaxScheme CompanyID must not be the stripped organisation number.');
        Assert.IsTrue(StrPos(CompanyID, '733078715601') > 0, 'PartyTaxScheme CompanyID must retain the full Swedish VAT digits.');
    end;

    [Test]
    procedure PEPPOL30SetupDefaultsToSEFormats()
    var
        PeppolSetup: Record "PEPPOL 3.0 Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 7723] A newly inserted PEPPOL 3.0 Setup defaults to the SE formats in the SE localization.
        Initialize();

        // [GIVEN] No PEPPOL 3.0 Setup record
        PeppolSetup.DeleteAll();

        // [WHEN] The setup record is (re)created
        PeppolSetup.GetSetup();

        // [THEN] Sales and Service formats default to the SE formats
        Assert.AreEqual(PeppolSetup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - SE Sales", PeppolSetup."PEPPOL 3.0 Sales Format", '');
        Assert.AreEqual(PeppolSetup."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - SE Service", PeppolSetup."PEPPOL 3.0 Service Format", '');
    end;

    [Test]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_SEOrgNo()
    var
        PeppolSetup: Record "PEPPOL 3.0 Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        SECountryCode: Code[10];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 7723] PEPPOL BIS3 export with the SE sales format: supplier and customer EndpointID carry the 10-digit organisation number under scheme 0007, while PartyTaxScheme keeps the full VAT.
        Initialize();

        // [GIVEN] The SE sales format is active
        PeppolSetup.GetSetup();
        PeppolSetup."PEPPOL 3.0 Sales Format" := PeppolSetup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - SE Sales";
        PeppolSetup.Modify();

        // [GIVEN] Company and customer in SE (VAT Scheme '0007') with "VAT Registration No." = 'SE733078715601', no GLN
        SECountryCode := SetupSECountryRegion(GetSEOrgNoSchemeID());
        SetupSECompany(SECountryCode);

        // [GIVEN] Posted Sales Invoice to an SE customer
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(CreateSECustomerWithAddress(SECountryCode)));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        PEPPOLXMLExportToBlob(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice(), TempBlob);

        // [THEN] Supplier and customer EndpointID = '7330787156' under schemeID '0007'
        InitXPathXMLReaderForInvoice(TempBlob);
        VerifySupplierEndpoint(GetExpectedSEOrgNo(), GetSEOrgNoSchemeID());
        VerifyCustomerEndpoint(GetExpectedSEOrgNo(), GetSEOrgNoSchemeID());
        // [THEN] Supplier PartyTaxScheme CompanyID keeps the full VAT
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          'cac:AccountingSupplierParty//cac:PartyTaxScheme/cbc:CompanyID', GetSETestVATRegNo());
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL SE BIS Billing Tests");

        CustLedgerEntry.DeleteAll();
        VATRegistrationNoFormat.DeleteAll();

        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL SE BIS Billing Tests");

            if not CompanyInformation.Get() then
                CompanyInformation.Insert();
            CompanyInformation.Validate(IBAN, 'GB29NWBK60161331926819');
            CompanyInformation.Validate("SWIFT Code", 'MIDLGB22Z0K');
            CompanyInformation.Validate("Bank Branch No.", '1234');
            CompanyInformation.Name := 'Test';
            CompanyInformation.Address := 'Test';
            CompanyInformation.City := 'Test';
            CompanyInformation."Post Code" := '1234';
            CompanyInformation.Modify(true);

            GeneralLedgerSetup.GetRecordOnce();
            GeneralLedgerSetup."VAT Reporting Date Usage" := GeneralLedgerSetup."VAT Reporting Date Usage"::Disabled;
            GeneralLedgerSetup.Modify(false);

            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateGeneralLedgerSetup();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibraryERMCountryData.UpdateSalesReceivablesSetup();
            LibraryERMCountryData.UpdateLocalData();
            LibrarySetupStorage.Save(Database::"Company Information");
            LibrarySetupStorage.Save(Database::"General Ledger Setup");

            IsInitialized := true;
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL SE BIS Billing Tests");
        end;

        ConfigureVATPostingSetup();
    end;

    local procedure ConfigureVATPostingSetup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');

        CustomerPostingGroup.DeleteAll();
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
    end;

    local procedure GetSETestVATRegNo(): Text
    begin
        exit('SE733078715601');
    end;

    local procedure GetExpectedSEOrgNo(): Text
    begin
        exit('7330787156');
    end;

    local procedure GetSEOrgNoSchemeID(): Text
    begin
        exit('0007');
    end;

    local procedure GetSEVATSchemeID(): Text
    begin
        exit('9955');
    end;

    local procedure SetupSECountryRegion(VATScheme: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get('SE') then begin
            CountryRegion.Init();
            CountryRegion.Code := 'SE';
            CountryRegion.Insert();
        end;
        CountryRegion."ISO Code" := 'SE';
        CountryRegion."VAT Scheme" := VATScheme;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure SetupSECompany(SECountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.GLN := '';
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation.Validate("Country/Region Code", SECountryCode);
        // Validating a changed Country/Region Code clears City and Post Code; restore them for the PEPPOL company checks
        CompanyInformation.City := 'Stockholm';
        CompanyInformation."Post Code" := '11432';
        CompanyInformation."VAT Registration No." := GetSETestVATRegNo();
        CompanyInformation.Modify();
    end;

    local procedure CreateSECustomerForUnitTest(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := SetupSECountryRegion(GetSEOrgNoSchemeID());
        Customer."VAT Registration No." := GetSETestVATRegNo();
        Customer.GLN := '';
        Customer."Use GLN in Electronic Document" := true;
        Customer.Modify();
    end;

    local procedure CreateSECustomerWithAddress(SECountryCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."Country/Region Code" := SECountryCode;
        Customer."VAT Registration No." := GetSETestVATRegNo();
        Customer.GLN := '';
        Customer."Use GLN in Electronic Document" := true;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), Database::"Sales Header"));
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesHeader.Validate("Sell-to E-Mail", 'sellto@example.com');
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBISElectronicDocumentFormatSalesInvoice(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := LibraryUtility.GenerateGUID();
        ElectronicDocumentFormat.Usage := "Electronic Document Format Usage"::"Sales Invoice";
        ElectronicDocumentFormat."Codeunit ID" := Codeunit::"Exp. Sales Inv. PEPPOL30";
        if ElectronicDocumentFormat.Insert() then;
        exit(ElectronicDocumentFormat.Code);
    end;

    local procedure PEPPOLXMLExportToBlob(DocumentVariant: Variant; FormatCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ClientFileName: Text[250];
    begin
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, FormatCode);
    end;

    local procedure InitXPathXMLReaderForInvoice(TempBlob: Codeunit "Temp Blob")
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, InvoiceNamespaceTxt);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure VerifySupplierEndpoint(EndpointID: Text; SchemeID: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:AccountingSupplierParty//cbc:EndpointID', EndpointID);
        LibraryXPathXMLReader.VerifyAttributeValue('cac:AccountingSupplierParty//cbc:EndpointID', 'schemeID', SchemeID);
    end;

    local procedure VerifyCustomerEndpoint(EndpointID: Text; SchemeID: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:AccountingCustomerParty//cbc:EndpointID', EndpointID);
        LibraryXPathXMLReader.VerifyAttributeValue('cac:AccountingCustomerParty//cbc:EndpointID', 'schemeID', SchemeID);
    end;
}
