// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Reflection;

codeunit 10992 "PEPPOL30 FR Sales Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Sales Header";
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30SalesValidation: Codeunit "PEPPOL30 Sales Validation";
        UnsupportedDocumentErr: Label 'The posted sales document type is not supported for PEPPOL 3.0 validation.';

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
        CheckSalesDocumentFR(SalesHeader);
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
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        UnsupportedDocumentErrorInfo: ErrorInfo;
    begin
        if not DataTypeMgt.GetRecordRef(RecordVariant, RecordRef) then
            exit;

        case RecordRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := RecordVariant;
                    CheckSalesInvoice(SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := RecordVariant;
                    CheckSalesCreditMemo(SalesCrMemoHeader);
                end;
            else begin
                UnsupportedDocumentErrorInfo.Message(UnsupportedDocumentErr);
                UnsupportedDocumentErrorInfo.ErrorType := ErrorType::Internal;
                Error(UnsupportedDocumentErrorInfo);
            end;
        end;
    end;

    local procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        CheckSalesDocumentFR(SalesHeader);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesInvoiceLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                PEPPOL30SalesValidation.ValidateDocumentLine(SalesLine);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TransferFields(SalesCrMemoHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        CheckSalesDocumentFR(SalesHeader);

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                PEPPOL30SalesValidation.ValidateDocumentLine(SalesLine);
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure CheckSalesDocumentFR(SalesHeader: Record "Sales Header")
    var
        CompanyInfo: Record "Company Information";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        CompanyInfo.Get();

        PEPPOL30SalesValidation.CheckCurrencyCode(SalesHeader."Currency Code");

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
        PEPPOL30SalesValidation.CheckCountryRegionCode(CompanyInfo."Country/Region Code");

        // French endpoint validation is performed by EDoc. Helpers before this standard validation.
        SalesHeader.TestField("Bill-to Name");
        SalesHeader.TestField("Bill-to Address");
        SalesHeader.TestField("Bill-to City");
        SalesHeader.TestField("Bill-to Post Code");
        SalesHeader.TestField("Bill-to Country/Region Code");
        PEPPOL30SalesValidation.CheckCountryRegionCode(SalesHeader."Bill-to Country/Region Code");

        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            if SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice then
                SalesHeader.TestField("Applies-to Doc. No.");

        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order] then
            SalesHeader.TestField("Shipment Date");

        SalesHeader.TestField("Your Reference");
        PEPPOL30SalesValidation.CheckShipToAddress(SalesHeader);
        SalesHeader.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
        CompanyInfo.TestField("SWIFT Code");
    end;
}