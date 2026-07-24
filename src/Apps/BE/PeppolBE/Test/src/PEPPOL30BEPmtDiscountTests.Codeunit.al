// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Peppol.BE.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Peppol;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 148720 "PEPPOL30 BE Pmt Disc Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PEPPOL] [BE] [Payment Discount]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        InvoiceNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;

    [Test]
    procedure PaymentDiscountNotDeductedFromTaxAmountsForBESalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
    begin
        // [SCENARIO 643204] For the Belgian PEPPOL format the taxable amount is calculated on the full amount,
        // i.e. the payment discount is NOT deducted from the VAT-taxable base, so the XML matches the invoice printout.
        Initialize();

        // [GIVEN] Payment Terms with a 3% payment discount
        PaymentTermsCode := CreatePaymentTermsWithDiscount(3);
        // [GIVEN] A customer that uses those payment terms
        CustomerNo := CreateCustomerWithAddressAndGLN();

        // [GIVEN] A posted sales invoice for 1 x 111.20 EUR with 21% VAT and the 3% payment discount terms
        PostSalesInvoiceWithPmtDiscount(SalesInvoiceHeader, CustomerNo, PaymentTermsCode, 111.2, 21);

        // [WHEN] The posted invoice is exported to PEPPOL BIS 3.0 using the Belgian sales format
        SalesInvoiceHeader.SetRecFilter();
        ExportInvoiceToBlob(SalesInvoiceHeader, TempBlob);

        // [THEN] The taxable/monetary totals are calculated on the full amount (111.20 / 134.55),
        // and NOT reduced by the payment discount (which would give 107.86 / 131.21 and fail BR-S-08).
        InitXPathXMLReaderForInvoice(TempBlob);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', '111.2');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', '111.2');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', '134.55');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:PayableAmount', '134.55');
        // [THEN] The tax subtotal taxable amount equals the full amount and no payment-discount allowance is emitted
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount', '111.2');
        LibraryXPathXMLReader.VerifyNodeAbsence('//cac:AllowanceCharge');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL30 BE Pmt Disc Tests");

        if IsInitialized then begin
            SetPeppolSalesFormatToBE();
            exit;
        end;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL30 BE Pmt Disc Tests");

        if not CompanyInformation.Get() then
            CompanyInformation.Insert();
        CompanyInformation.Name := 'Test';
        CompanyInformation.Address := 'Test';
        CompanyInformation.City := 'Test';
        CompanyInformation."Post Code" := '1234';
        CompanyInformation."Country/Region Code" := 'DK';
        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CompanyInformation.Validate(GLN, '1234567891231');
        CompanyInformation.Validate("Use GLN in Electronic Document", true);
        CompanyInformation.Modify(true);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();

        EnableAdjustForPaymentDiscount();

        LibrarySetupStorage.Save(Database::"Company Information");
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL30 BE Pmt Disc Tests");

        SetPeppolSalesFormatToBE();
    end;

    local procedure SetPeppolSalesFormatToBE()
    var
        PEPPOLSetup: Record "PEPPOL 3.0 Setup";
    begin
        PEPPOLSetup.GetSetup();
        PEPPOLSetup."PEPPOL 3.0 Sales Format" := PEPPOLSetup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - BE Sales";
        PEPPOLSetup.Modify();
    end;

    local procedure EnableAdjustForPaymentDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreatePaymentTermsWithDiscount(DiscountPct: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Discount Date Calculation", '<8D>');
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCustomerWithAddressAndGLN(): Code[20]
    var
        CountryRegion: Record "Country/Region";
        ShipToAddress: Record "Ship-to Address";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);

        ShipToAddress."Customer No." := Customer."No.";
        ShipToAddress.Code := LibraryUtility.GenerateRandomCode(ShipToAddress.FieldNo(Code), Database::"Ship-to Address");
        ShipToAddress.Address := Customer.Address;
        ShipToAddress.City := Customer.City;
        ShipToAddress."Post Code" := Customer."Post Code";
        ShipToAddress."Country/Region Code" := Customer."Country/Region Code";
        ShipToAddress.Validate(Name, Customer.Name);
        if ShipToAddress.Insert() then;

        if CountryRegion.Get(Customer."Country/Region Code") and (CountryRegion."ISO Code" <> '') then
            Customer."VAT Registration No." := CountryRegion."ISO Code" + LibraryUtility.GenerateGUID()
        else
            Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Validate(GLN, '1234567891231');
        Customer."Use GLN in Electronic Document" := true;
        Customer."Ship-to Code" := ShipToAddress.Code;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure PostSalesInvoiceWithPmtDiscount(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20]; PaymentTermsCode: Code[10]; UnitPrice: Decimal; VATPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Validate("Sell-to E-Mail", 'sellto@example.com');
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("VAT Prod. Posting Group", CreateVATPostingSetupWithPmtDiscount(SalesHeader."VAT Bus. Posting Group", VATPct));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateVATPostingSetupWithPmtDiscount(VATBusPostingGroup: Code[20]; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Tax Category", 'S');
        VATPostingSetup."Adjust for Payment Discount" := true;
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure ExportInvoiceToBlob(var SalesInvoiceHeader: Record "Sales Invoice Header"; var TempBlob: Codeunit "Temp Blob")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FormatCode: Code[20];
        ClientFileName: Text[250];
    begin
        FormatCode := LibraryUtility.GenerateGUID();
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := FormatCode;
        ElectronicDocumentFormat.Usage := ElectronicDocumentFormat.Usage::"Sales Invoice";
        ElectronicDocumentFormat."Codeunit ID" := Codeunit::"Exp. Sales Inv. PEPPOL30";
        if ElectronicDocumentFormat.Insert() then;

        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, FormatCode);
    end;

    local procedure InitXPathXMLReaderForInvoice(TempBlob: Codeunit "Temp Blob")
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, InvoiceNamespaceTxt);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;
}
