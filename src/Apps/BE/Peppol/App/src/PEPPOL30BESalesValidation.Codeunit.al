// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Peppol;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Reflection;

codeunit 37311 "PEPPOL30 BE Sales Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Sales Header";
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30SalesValidation: Codeunit "PEPPOL30 Sales Validation";
        MissingCompInfGLNOrVATRegNoOrEnterpNoErr: Label 'You must specify either GLN, VAT Registration No. or Enterprise No. in %1.', Comment = '%1=Company Information';
        MissingCustGLNOrVATRegNoOrEnterpNoErr: Label 'You must specify either GLN, VAT Registration No. or Enterprise No. for Customer %1.', Comment = '%1 = Customer No.';
        WrongLengthErr: Label 'should be %1 characters long', Comment = '%1 - field length';
        IsHandled: Boolean;

    trigger OnRun()
    begin
        ValidateDocument(Rec);
        ValidateDocumentLines(Rec);
    end;

    procedure ValidateDocument(RecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader := RecordVariant;
        CheckSalesDocument(SalesHeader);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        PEPPOL30SalesValidation.ValidateDocumentLines(RecordVariant);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        PEPPOL30SalesValidation.ValidateDocumentLine(RecordVariant);
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        exit(PEPPOL30SalesValidation.ValidateLineTypeAndDescription(RecordVariant));
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        UnsupportedDocumentErr: Label 'The posted sales document type is not supported for PEPPOL 3.0 validation.';
    begin
        if not DataTypeMgt.GetRecordRef(RecordVariant, RecordRef) then
            exit;

        // BE-specific: Validate document header with Enterprise No. check, then delegate line validation to W1
        case RecordRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := RecordVariant;
                    SalesHeader.TransferFields(SalesInvoiceHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    CheckSalesDocument(SalesHeader);
                    PEPPOL30SalesValidation.ValidateDocumentLines(SalesHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := RecordVariant;
                    SalesHeader.TransferFields(SalesCrMemoHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    CheckSalesDocument(SalesHeader);
                    PEPPOL30SalesValidation.ValidateDocumentLines(SalesHeader);
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    local procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
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

        // BE-specific: Include Enterprise No. in the check
        OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader, CompanyInfo, IsHandled);
        if not IsHandled then
            if CompanyInfo.GLN + CompanyInfo."VAT Registration No." + GetFieldValueByName(CompanyInfo, 'Enterprise No.') = '' then
                Error(MissingCompInfGLNOrVATRegNoOrEnterpNoErr, CompanyInfo.TableCaption());

        SalesHeader.TestField("Bill-to Name");
        SalesHeader.TestField("Bill-to Address");
        SalesHeader.TestField("Bill-to City");
        SalesHeader.TestField("Bill-to Post Code");
        SalesHeader.TestField("Bill-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Bill-to Country/Region Code");

        // BE-specific: Include Enterprise No. in the check
        OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader, Customer, IsHandled);
        if not IsHandled then
            if (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Credit Memo"]) and
               Customer.Get(SalesHeader."Bill-to Customer No.")
            then
                if (Customer.GLN + Customer."VAT Registration No." + GetFieldValueByName(Customer, 'Enterprise No.')) = '' then
                    Error(MissingCustGLNOrVATRegNoOrEnterpNoErr, Customer."No.");

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

    local procedure CheckCurrencyCode(CurrencyCode: Code[10])
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
            exit;
        end;

        if StrLen(Currency.Code) <> MaxCurrencyCodeLength then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, MaxCurrencyCodeLength));
    end;

    local procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
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

    local procedure CheckShipToAddress(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Ship-to Address");
        SalesHeader.TestField("Ship-to City");
        SalesHeader.TestField("Ship-to Post Code");
        SalesHeader.TestField("Ship-to Country/Region Code");
        CheckCountryRegionCode(SalesHeader."Ship-to Country/Region Code");
    end;

    local procedure GetFieldValueByName(RecordVariant: Variant; FieldName: Text): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        RecRef.GetTable(RecordVariant);
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if FieldRef.Name = FieldName then
                exit(Format(FieldRef.Value));
        end;
        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCompanyVATRegNo(SalesHeader: Record "Sales Header"; CompanyInfo: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
}
