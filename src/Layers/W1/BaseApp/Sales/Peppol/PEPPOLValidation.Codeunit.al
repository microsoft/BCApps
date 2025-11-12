// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 1620 "PEPPOL Validation"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckSalesDocument(Rec);
        CheckSalesDocumentLines(Rec);
    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";
        OutsideScopeVATBreakdowns: Dictionary of [Text, Text];
#pragma warning disable AA0470
        WrongLengthErr: Label 'should be %1 characters long';
        EmptyUnitOfMeasureErr: Label 'You must specify a valid International Standard Code for the Unit of Measure for %1.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order), 2 - document number';
#pragma warning restore AA0470
        MissingDescriptionErr: Label 'Description field is empty. \Field must be filled if you want to send the posted document as an electronic document.', Comment = 'Parameter 1 - document type (), 2 - document number';
#pragma warning disable AA0470
        MissingCustGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. for Customer %1.';
#pragma warning restore AA0470
        MissingCompInfGLNOrVATRegNoErr: Label 'You must specify either GLN or VAT Registration No. in %1.', Comment = '%1=Company Information';
        NegativeUnitPriceErr: Label 'The unit price is negative in %1. It cannot be negative if you want to send the posted document as an electronic document. \\Do you want to continue?', Comment = '%1 - record ID';
        VatMustBeZeroForCategoryErr: Label 'VAT % must be 0 for tax category code %1', Comment = '%1 - Tax Category code';
        OnlyOneOCategoryVatPostingSetupErr: Label 'There can be only one tax subtotal present on invoice used with "Not subject to VAT" (O) tax category.';
        VATGreaterThanZeroErr: Label 'Line should have greater VAT than 0% for tax category %1', Comment = '%1 - Tax Category code';

    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        IsHandled := false;
        OnBeforeCheckSalesDocument(SalesHeader, CompanyInfo, IsHandled);
        if IsHandled then
            exit;

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

        IsHandled := false;
        OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader, CompanyInfo, IsHandled);
        if not IsHandled then
            if CompanyInfo.GLN + CompanyInfo."VAT Registration No." = '' then
                Error(MissingCompInfGLNOrVATRegNoErr, CompanyInfo.TableCaption());
        SalesHeader.TestField("Bill-to Name");
        SalesHeader.TestField("Bill-to Address");
        SalesHeader.TestField("Bill-to City");
        SalesHeader.TestField("Bill-to Post Code");
        SalesHeader.TestField("Bill-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Bill-to Country/Region Code");

        IsHandled := false;
        OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader, Customer, IsHandled);
        if not IsHandled then
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

        IsHandled := false;
        OnCheckSalesDocumentOnBeforeCheckYourReference(SalesHeader, IsHandled);
        if not IsHandled then
            SalesHeader.TestField("Your Reference");

        CheckShipToAddress(SalesHeader);
        SalesHeader.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
        CompanyInfo.TestField("SWIFT Code");

        OnAfterCheckSalesDocument(SalesHeader, CompanyInfo);
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
        PEPPOLMgt: Codeunit "PEPPOL Management";
        unitCode: Text;
        unitCodeListID: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocumentLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        PEPPOLMgt.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
        if (SalesLine.Type <> SalesLine.Type::" ") and (SalesLine."No." <> '') and (unitCode = '') then
            Error(EmptyUnitOfMeasureErr, SalesLine."Unit of Measure Code");

        IsHandled := false;
        OnCheckSalesDocumentLineOnBeforeCheckEmptyDescription(SalesLine, IsHandled);
        if not IsHandled then
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

    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
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

    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
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

#if not CLEAN25
    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    procedure CheckServiceHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        PEPPOLServiceValidation: Codeunit "PEPPOL Service Validation";
    begin
        PEPPOLServiceValidation.CheckServiceHeader(ServiceHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    procedure CheckServiceInvoice(ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header")
    var
        PEPPOLServiceValidation: Codeunit "PEPPOL Service Validation";
    begin
        PEPPOLServiceValidation.CheckServiceInvoice(ServiceInvoiceHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record Microsoft.Service.History."Service Cr.Memo Header")
    var
        PEPPOLServiceValidation: Codeunit "PEPPOL Service Validation";
    begin
        PEPPOLServiceValidation.CheckServiceCreditMemo(ServiceCrMemoHeader);
    end;
#endif

    local procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
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

    local procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        CompanyInfo: Record "Company Information";
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

    local procedure CheckShipToAddress(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipToAddress(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.TestField("Ship-to Address");
        SalesHeader.TestField("Ship-to City");
        SalesHeader.TestField("Ship-to Post Code");
        SalesHeader.TestField("Ship-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Ship-to Country/Region Code");
    end;

    local procedure CheckTaxCategory(SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLManagement: Codeunit "PEPPOL Management";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.TestField("Tax Category");

        case true of
            PEPPOLManagement.IsStandardVATCategory(VATPostingSetup."Tax Category"):
                this.EnsurePositiveRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
            PEPPOLManagement.IsOutsideScopeVATCategory(VATPostingSetup."Tax Category"):
                begin
                    this.EnsureZeroRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
                    this.EnsureSingleOutsideScopeVATBreakdown(SalesLine);
                end;
            PEPPOLManagement.IsZeroVatCategory(VATPostingSetup."Tax Category"):
                this.EnsureZeroRate(SalesLine."VAT %", VATPostingSetup."Tax Category");
        end
    end;

    local procedure EnsureZeroRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    begin
        if VatPercent > 0 then
            Error(VatMustBeZeroForCategoryErr, TaxCategoryCode);
    end;

    local procedure EnsurePositiveRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    begin
        if VatPercent = 0 then
            Error(VATGreaterThanZeroErr, TaxCategoryCode);
    end;

    local procedure EnsureSingleOutsideScopeVATBreakdown(SalesLine: Record "Sales Line")
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header"; CompanyInfo: Record "Company Information")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToAddress(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentLineOnBeforeCheckEmptyDescription(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocument(var SalesHeader: Record "Sales Header"; var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(SalesLine, ServiceLine);
    end;

    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line")
    begin
        OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(SalesLine, ServiceInvoiceLine);
    end;

    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line")
    begin
        OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(SalesLine, ServiceCrMemoLine);
    end;

    [Obsolete('Moved to codeunit PEPPOL Service Validation', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader: Record "Sales Header"; CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckYourReference(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

