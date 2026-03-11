// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Reflection;
using System.Utilities;

codeunit 37203 "PEPPOL30 Sales Validation Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ConfirmManagement: Codeunit "Confirm Management";
        OutsideScopeVATBreakdowns: Dictionary of [Text, Text];
        EmptyUnitOfMeasureErr: Label 'You must specify a valid International Standard Code for the Unit of Measure for %1.', Comment = '%1 - Unit of Measure Code';
        MissingCompInfGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. in %1.', Comment = '%1=Company Information';
        MissingCustGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. for Customer %1.', Comment = '%1 = Customer No.';
        MissingDescriptionErr: Label 'Description field is empty. \Field must be filled if you want to send the posted document as an electronic document.', Comment = 'Parameter 1 - document type (), 2 - document number';
        NegativeUnitPriceErr: Label 'The unit price is negative in %1. It cannot be negative if you want to send the posted document as an electronic document. \\Do you want to continue?', Comment = '%1 - record ID';
        OnlyOneOCategoryVatPostingSetupErr: Label 'There can be only one tax subtotal present on invoice used with "Not subject to VAT" (O) tax category.';
        VATGreaterThanZeroErr: Label 'Line should have greater VAT than 0% for tax category %1', Comment = '%1 - Tax Category code';
        VatMustBeZeroForCategoryErr: Label 'VAT % must be 0 for tax category code %1', Comment = '%1 - Tax Category code';
        WrongLengthErr: Label 'should be %1 characters long', Comment = '%1 - field length';


    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        CheckCurrencyCode(SalesHeader."Currency Code");

        if SalesHeader."Responsibility Center" <> '' then begin
            ResponsibilityCenter.Get(SalesHeader."Responsibility Center");
            ResponsibilityCenter.TestField(Name);
            ResponsibilityCenter.TestField(Address);
            ResponsibilityCenter.TestField(City);
            ResponsibilityCenter.TestField("Post Code");
            ResponsibilityCenter.TestField("Country/Region Code");
        end else begin
            CompanyInfo.TestField(Name);
            CompanyInfo.TestField(Address);
            CompanyInfo.TestField(City);
            CompanyInfo.TestField("Post Code");
        end;

        CompanyInfo.TestField("Country/Region Code");
        CheckCountryRegionCode(CompanyInfo."Country/Region Code");

        if CompanyInfo.GLN + CompanyInfo."VAT Registration No." = '' then
            Error(MissingCompInfGLNOrVATRegNoErr, CompanyInfo.TableCaption());

        SalesHeader.TestField("Bill-to Name");
        SalesHeader.TestField("Bill-to Address");
        SalesHeader.TestField("Bill-to City");
        SalesHeader.TestField("Bill-to Post Code");
        SalesHeader.TestField("Bill-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Bill-to Country/Region Code");

        if (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Credit Memo"]) and
           Customer.Get(SalesHeader."Bill-to Customer No.")
        then
            if (Customer.GLN + Customer."VAT Registration No.") = '' then
                Error(MissingCustGLNOrVATRegNoErr, Customer."No.");

        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            if SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice then
                SalesHeader.TestField("Applies-to Doc. No.");

        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order] then
            SalesHeader.TestField("Shipment Date");

        SalesHeader.TestField("Your Reference");

        CheckShipToAddress(SalesHeader);
        SalesHeader.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
        CompanyInfo.TestField("SWIFT Code");
    end;

    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                CheckSalesDocumentLine(SalesLine)
            until SalesLine.Next() = 0;
    end;

    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PEPPOL30Management: Codeunit "PEPPOL30";
        unitCode: Text;
        unitCodeListID: Text;
    begin
        PEPPOL30Management.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
        if (SalesLine.Type <> SalesLine.Type::" ") and (SalesLine."No." <> '') and (unitCode = '') then
            Error(EmptyUnitOfMeasureErr, SalesLine."Unit of Measure Code");

        if CheckSalesLineTypeAndDescription(SalesLine) then
            Error(MissingDescriptionErr);

        if (SalesLine.Type <> SalesLine.Type::" ") and (SalesLine."No." <> '') then begin
            // Not a description line
            if GeneralLedgerSetup.UseVat() then
                SalesLine.TestField("VAT Prod. Posting Group");
            this.CheckTaxCategory(SalesLine);

            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."Unit Price" < 0) then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(NegativeUnitPriceErr, SalesLine.RecordId), false) then
                    Error('');
        end;
    end;

    procedure CheckPostedDocument(PostedDocumentVariant: Variant)
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        UnsupportedDocumentErr: Label 'The posted sales document type is not supported for PEPPOL 3.0 validation.';
    begin
        if not DataTypeMgt.GetRecordRef(PostedDocumentVariant, RecordRef) then
            exit;

        case RecordRef.Number() of
            Database::"Sales Invoice Header":
                CheckSalesInvoice(PostedDocumentVariant);
            Database::"Sales Cr.Memo Header":
                CheckSalesCreditMemo(PostedDocumentVariant);
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    internal procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        CheckSalesDocument(SalesHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesInvoiceLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                CheckSalesDocumentLine(SalesLine);
            until SalesInvoiceLine.Next() = 0;
    end;

    internal procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesCrMemoHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        CheckSalesDocument(SalesHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                CheckSalesDocumentLine(SalesLine);
            until SalesCrMemoLine.Next() = 0;
    end;

    internal procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        MaxCurrencyCodeLength: Integer;
    begin
        MaxCurrencyCodeLength := 3;

        if CurrencyCode = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            CurrencyCode := GLSetup."LCY Code";
        end;

        if not Currency.Get(CurrencyCode) then begin
            if StrLen(CurrencyCode) <> MaxCurrencyCodeLength then
                GLSetup.FieldError("LCY Code", StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
            exit; // Valid
        end;

        if StrLen(Currency.Code) <> MaxCurrencyCodeLength then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
    end;

    internal procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        MaxCountryCodeLength: Integer;
    begin
        MaxCountryCodeLength := 2;

        if CountryRegionCode = '' then begin
            CompanyInfo.Get();
            CompanyInfo.TestField("Country/Region Code");
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        CountryRegion.TestField("ISO Code");
        if StrLen(CountryRegion."ISO Code") <> MaxCountryCodeLength then
            CountryRegion.FieldError("ISO Code", StrSubstNo(WrongLengthErr, MaxCountryCodeLength));
    end;

    internal procedure CheckShipToAddress(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Ship-to Address");
        SalesHeader.TestField("Ship-to City");
        SalesHeader.TestField("Ship-to Post Code");
        SalesHeader.TestField("Ship-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Ship-to Country/Region Code");
    end;

    internal procedure CheckTaxCategory(SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.TestField("Tax Category");

        case true of
            PEPPOL30Management.IsStandardVATCategory(VATPostingSetup."Tax Category"):
                this.EnsurePositiveRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
            PEPPOL30Management.IsOutsideScopeVATCategory(VATPostingSetup."Tax Category"):
                begin
                    this.EnsureZeroRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
                    this.EnsureSingleOutsideScopeVATBreakdown(SalesLine);
                end;
            PEPPOL30Management.IsZeroVatCategory(VATPostingSetup."Tax Category"):
                this.EnsureZeroRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
        end
    end;

    internal procedure EnsureZeroRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    begin
        if VatPercent > 0 then
            Error(VatMustBeZeroForCategoryErr, TaxCategoryCode);
    end;

    internal procedure EnsurePositiveRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    begin
        if VatPercent = 0 then
            Error(VATGreaterThanZeroErr, TaxCategoryCode);
    end;

    internal procedure EnsureSingleOutsideScopeVATBreakdown(SalesLine: Record "Sales Line")
    var
        BreakdownKey: Text;
    begin
        // Check if separate VAT amount line won't be created to ensure that only one VAT breakdown line is created in PEPPOL document
        BreakdownKey := Format(SalesLine."VAT Calculation Type") + '|' + SalesLine."Tax Group Code";

        if OutsideScopeVATBreakdowns.Count() > 0 then begin
            if not OutsideScopeVATBreakdowns.ContainsKey(BreakdownKey) then
                Error(OnlyOneOCategoryVatPostingSetupErr);
        end else
            OutsideScopeVATBreakdowns.Add(BreakdownKey, Format(SalesLine."VAT %"));
    end;

    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    begin
        if (SalesLine.Type <> SalesLine.Type::" ") and (SalesLine.Description = '') then
            exit(true);
    end;
}