// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 148505 "E-Doc DE VAT Rates Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;
    Permissions =
        tabledata "Sales Invoice Header" = RIM,
        tabledata "Sales Invoice Line" = RIM,
        tabledata "Sales Cr.Memo Header" = RI,
        tabledata "Sales Cr.Memo Line" = RI;

    var
        Assert: Codeunit Assert;
        ExportXRechnung: Codeunit "Export XRechnung Document";
        ExportZUGFeRD: Codeunit "Export ZUGFeRD Document";
        VATBusPostingGroup: Code[20];

    [Test]
    procedure XRechnungOutsideScopeInvoiceOmitsRates()
    begin
        VerifyOutsideScopeRates(false, false, false);
    end;

    [Test]
    procedure XRechnungOutsideScopeCreditMemoOmitsRates()
    begin
        VerifyOutsideScopeRates(false, true, false);
    end;

    [Test]
    procedure ZUGFeRDOutsideScopeInvoiceOmitsRates()
    begin
        VerifyOutsideScopeRates(true, false, false);
    end;

    [Test]
    procedure ZUGFeRDOutsideScopeCreditMemoOmitsRates()
    begin
        VerifyOutsideScopeRates(true, true, false);
    end;

    [Test]
    procedure XRechnungOutsideScopeRatesUsePostingSetupFallback()
    begin
        VerifyOutsideScopeRates(false, false, true);
    end;

    [Test]
    procedure ZUGFeRDOutsideScopeRatesUsePostingSetupFallback()
    begin
        VerifyOutsideScopeRates(true, false, true);
    end;

    [Test]
    procedure XRechnungPreservesStandardRatesAndTotals()
    begin
        VerifyStandardRates(false, false);
    end;

    [Test]
    procedure ZUGFeRDPreservesStandardRatesAndTotals()
    begin
        VerifyStandardRates(true, false);
    end;

    [Test]
    procedure XRechnungPreservesStandardCreditMemoRatesAndTotals()
    begin
        VerifyStandardRates(false, true);
    end;

    [Test]
    procedure ZUGFeRDPreservesStandardCreditMemoRatesAndTotals()
    begin
        VerifyStandardRates(true, true);
    end;

    [Test]
    procedure XRechnungInvoicePreservesStandardAllowanceChargeRates()
    begin
        VerifyStandardAllowanceChargeRates(false, false);
    end;

    [Test]
    procedure XRechnungCreditMemoPreservesStandardAllowanceChargeRates()
    begin
        VerifyStandardAllowanceChargeRates(false, true);
    end;

    [Test]
    procedure ZUGFeRDInvoicePreservesStandardAllowanceChargeRates()
    begin
        VerifyStandardAllowanceChargeRates(true, false);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoPreservesStandardAllowanceChargeRates()
    begin
        VerifyStandardAllowanceChargeRates(true, true);
    end;

    local procedure VerifyStandardAllowanceChargeRates(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
        TaxPath, RateName: Text;
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'S', 19, 90, 10, false, false);
        AddLine(Header, 20000, 'S', 19, 5, 0, true, false);
        AddLine(Header, 30000, 'S', 19, -2, 0, true, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        if IsCII then begin
            TaxPath := '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]/*[local-name()="CategoryTradeTax"]';
            RateName := 'RateApplicablePercent';
        end else begin
            TaxPath := '/*/*[local-name()="AllowanceCharge"]/*[local-name()="TaxCategory"]';
            RateName := 'Percent';
        end;
        AssertNodeCount(Document, TaxPath, 3);
        AssertNodeCount(Document, TaxPath + '/*[local-name()="' + RateName + '" and number(.)=19]', 3);
        AssertBreakdown(Document, IsCII, 'S', 19, 93, 17.67);
        AssertPayable(Document, IsCII, 110.67);
    end;

    local procedure VerifyOutsideScopeRates(IsCII: Boolean; IsCreditMemo: Boolean; UseSetupCategory: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
        LineTaxPath, DocumentTaxPath, RateName: Text;
    begin
        // BR-O-05/06/07: assert absence, not a zero value, and assert the parent nodes exist.
        CreateFixture(Header);
        AddLine(Header, 10000, 'O', 0, 90, 10, false, UseSetupCategory);
        AddLine(Header, 20000, 'O', 0, 5, 0, true, UseSetupCategory);
        AddLine(Header, 30000, 'O', 0, -2, 0, true, UseSetupCategory);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        if IsCII then begin
            LineTaxPath := '//*[local-name()="SpecifiedLineTradeSettlement"]/*[local-name()="ApplicableTradeTax"]';
            DocumentTaxPath := '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]/*[local-name()="CategoryTradeTax"]';
            RateName := 'RateApplicablePercent';
        end else begin
            LineTaxPath := '//*[local-name()="ClassifiedTaxCategory"]';
            DocumentTaxPath := '/*/*[local-name()="AllowanceCharge"]/*[local-name()="TaxCategory"]';
            RateName := 'Percent';
        end;
        AssertNodeCount(Document, LineTaxPath, 1);
        AssertNodeCount(Document, DocumentTaxPath, 3);
        AssertNodeCount(Document, LineTaxPath + '/*[local-name()="' + RateName + '"]', 0);
        AssertNodeCount(Document, DocumentTaxPath + '/*[local-name()="' + RateName + '"]', 0);
        // The rate remains required in the VAT breakdown of the declared XRechnung profile (BR-DE-14).
        if IsCII then
            AssertNodeCount(Document, '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="ApplicableTradeTax"]/*[local-name()="RateApplicablePercent" and number(.)=0]', 1)
        else
            AssertNodeCount(Document, '/*/*[local-name()="TaxTotal"]/*[local-name()="TaxSubtotal"]/*[local-name()="TaxCategory"]/*[local-name()="Percent" and number(.)=0]', 1);
        AssertPayable(Document, IsCII, 93);
    end;

    local procedure VerifyStandardRates(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'S', 7, 100, 0, false, false);
        AddLine(Header, 20000, 'S', 19, 200, 0, false, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, 'S', 7, 100, 7);
        AssertBreakdown(Document, IsCII, 'S', 19, 200, 38);
        AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        AssertPayable(Document, IsCII, 345);
    end;

    local procedure CreateFixture(var Header: Record "Sales Invoice Header")
    var
        EDocumentService: Record "E-Document Service";
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
    begin
        // These are isolated posted-record fixtures for the real XML serializers, not posting tests.
        EDocumentService.SetFilter("Document Format", '%1|%2', EDocumentService."Document Format"::XRechnung, EDocumentService."Document Format"::ZUGFeRD);
        EDocumentService.DeleteAll();
        VATBusPostingGroup := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        if not CountryRegion.Get('DE') then begin
            CountryRegion.Code := 'DE';
            CountryRegion.Insert();
        end;
        CountryRegion."ISO Code" := 'DE';
        CountryRegion.Modify();
        CompanyInformation.Get();
        CompanyInformation.Name := 'VAT XML test seller';
        CompanyInformation.Address := 'Test Street 1';
        CompanyInformation.City := 'Berlin';
        CompanyInformation."Post Code" := '10115';
        CompanyInformation."Country/Region Code" := 'DE';
        CompanyInformation."VAT Registration No." := 'DE123456789';
        CompanyInformation.GLN := '1234567890128';
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation."E-Mail" := 'seller@example.com';
        CompanyInformation."Contact Person" := 'XML test';
        CompanyInformation."Phone No." := '030123456';
        CompanyInformation.Modify();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'EUR';
        GeneralLedgerSetup.Modify();
        Customer."No." := VATBusPostingGroup;
        Customer.Name := 'VAT XML test buyer';
        Customer.GLN := '1234567890135';
        Customer."Use GLN in Electronic Document" := true;
        Customer."E-Mail" := 'buyer@example.com';
        Customer.Insert();
        Header.Init();
        Header."No." := VATBusPostingGroup;
        Header."Sell-to Customer No." := Customer."No.";
        Header."Bill-to Customer No." := Customer."No.";
        Header."Sell-to Customer Name" := Customer.Name;
        Header."Bill-to Name" := Customer.Name;
        Header."Bill-to Address" := 'Test Street 2';
        Header."Bill-to City" := 'Berlin';
        Header."Bill-to Post Code" := '10115';
        Header."Bill-to Country/Region Code" := 'DE';
        Header."VAT Country/Region Code" := 'DE';
        Header."VAT Registration No." := 'DE987654321';
        Header."Buyer Reference" := 'VAT-XML-TEST';
        Header."Document Date" := 20260115D;
        Header."Posting Date" := 20260115D;
        Header."Due Date" := 20260215D;
        Header.Insert();
    end;

    local procedure AddLine(Header: Record "Sales Invoice Header"; LineNo: Integer; Category: Code[10]; Rate: Decimal; NetAmount: Decimal; InvoiceDiscount: Decimal; IsCharge: Boolean; UseSetupCategory: Boolean)
    var
        Line: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        ItemCharge: Record "Item Charge";
        VATProdPostingGroup: Code[20];
    begin
        VATProdPostingGroup := CopyStr(Category + Format(Rate, 0, 9), 1, 20);
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then begin
            VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
            VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
            VATPostingSetup."VAT %" := Rate;
            VATPostingSetup."Tax Category" := Category;
            if Category in ['E', 'O'] then begin
                VATClause.Code := CopyStr(CopyStr(VATBusPostingGroup, 1, 18) + Category, 1, MaxStrLen(VATClause.Code));
                if Category = 'O' then begin
                    VATClause.Description := 'Not subject to VAT';
                    VATClause."VATEX Code" := 'VATEX-EU-O';
                end else
                    VATClause.Description := 'Exempt from VAT';
                VATClause.Insert();
                VATPostingSetup."VAT Clause Code" := VATClause.Code;
            end;
            VATPostingSetup.Insert();
        end;
        Line."Document No." := Header."No.";
        Line."Line No." := LineNo;
        Line.Type := Line.Type::"G/L Account";
        Line."No." := 'VAT-XML-TEST';
        if IsCharge then begin
            ItemCharge."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
            ItemCharge."E-Invoice Mapping" := ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge";
            ItemCharge.Insert();
            Line.Type := Line.Type::"Charge (Item)";
            Line."No." := ItemCharge."No.";
        end;
        Line.Description := 'VAT XML test line';
        Line.Quantity := 1;
        Line."Unit of Measure Code" := 'C62';
        Line."VAT Bus. Posting Group" := VATBusPostingGroup;
        Line."VAT Prod. Posting Group" := VATProdPostingGroup;
        if not UseSetupCategory then
            Line."Tax Category" := Category;
        Line."VAT %" := Rate;
        Line.Amount := NetAmount;
        Line."Amount Including VAT" := NetAmount * (1 + Rate / 100);
        Line."Inv. Discount Amount" := InvoiceDiscount;
        Line."Line Amount" := NetAmount + InvoiceDiscount;
        Line."Unit Price" := Line."Line Amount";
        Line.Insert();
    end;

    local procedure ExportFixture(Header: Record "Sales Invoice Header"; IsCII: Boolean; IsCreditMemo: Boolean; var Document: XmlDocument)
    var
        CreditHeader: Record "Sales Cr.Memo Header";
        InvoiceLine: Record "Sales Invoice Line";
        CreditLine: Record "Sales Cr.Memo Line";
        TempBlob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
    begin
        TempBlob.CreateOutStream(Output, TextEncoding::UTF8);
        if IsCreditMemo then begin
            CreditHeader.TransferFields(Header);
            CreditHeader.Insert();
            InvoiceLine.SetRange("Document No.", Header."No.");
            if InvoiceLine.FindSet() then
                repeat
                    CreditLine.Init();
                    CreditLine.TransferFields(InvoiceLine);
                    CreditLine.Insert();
                until InvoiceLine.Next() = 0;
            if IsCII then
                ExportZUGFeRD.CreateXML(CreditHeader, Output)
            else
                ExportXRechnung.CreateXML(CreditHeader, Output);
        end else
            if IsCII then
                ExportZUGFeRD.CreateXML(Header, Output)
            else
                ExportXRechnung.CreateXML(Header, Output);
        TempBlob.CreateInStream(Input, TextEncoding::UTF8);
        XmlDocument.ReadFrom(Input, Document);
    end;

    local procedure BreakdownPath(IsCII: Boolean): Text
    begin
        if IsCII then
            exit('//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="ApplicableTradeTax"]');
        exit('/*/*[local-name()="TaxTotal"]/*[local-name()="TaxSubtotal"]');
    end;

    local procedure AssertBreakdown(Document: XmlDocument; IsCII: Boolean; Category: Text; Rate: Decimal; Basis: Decimal; Tax: Decimal)
    var
        Path: Text;
    begin
        if IsCII then begin
            Path := BreakdownPath(true) + '[*[local-name()="CategoryCode"]="' + Category + '" and *[local-name()="RateApplicablePercent"]=' + Format(Rate, 0, 9) + ']';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="BasisAmount"]', Basis);
            AssertDecimal(Document, Path + '/*[local-name()="CalculatedAmount"]', Tax);
        end else begin
            Path := BreakdownPath(false) + '[*[local-name()="TaxCategory"][*[local-name()="ID"]="' + Category + '" and *[local-name()="Percent"]=' + Format(Rate, 0, 9) + ']]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="TaxableAmount"]', Basis);
            AssertDecimal(Document, Path + '/*[local-name()="TaxAmount"]', Tax);
        end;
    end;

    local procedure AssertPayable(Document: XmlDocument; IsCII: Boolean; Amount: Decimal)
    begin
        if IsCII then
            AssertDecimal(Document, '//*[local-name()="SpecifiedTradeSettlementHeaderMonetarySummation"]/*[local-name()="DuePayableAmount"]', Amount)
        else
            AssertDecimal(Document, '/*/*[local-name()="LegalMonetaryTotal"]/*[local-name()="PayableAmount"]', Amount);
    end;

    local procedure AssertNodeCount(Document: XmlDocument; Path: Text; Expected: Integer)
    var
        Nodes: XmlNodeList;
    begin
        Document.SelectNodes(Path, Nodes);
        Assert.AreEqual(Expected, Nodes.Count(), Path);
    end;

    local procedure AssertDecimal(Document: XmlDocument; Path: Text; Expected: Decimal)
    var
        Node: XmlNode;
        Actual: Decimal;
    begin
        Assert.IsTrue(Document.SelectSingleNode(Path, Node), Path);
        Evaluate(Actual, Node.AsXmlElement().InnerText(), 9);
        Assert.AreEqual(Expected, Actual, Path);
    end;
}
