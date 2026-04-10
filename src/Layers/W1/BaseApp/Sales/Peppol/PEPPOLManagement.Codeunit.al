// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.IO;
using System.Telemetry;
using System.Text;
using System.Utilities;

/// <summary>
/// Provides helper functions for extracting and formatting data for PEPPOL electronic invoice generation.
/// </summary>
codeunit 1605 "PEPPOL Management"
{

    trigger OnRun()
    begin
    end;

    var
        ProcessedDocType: Enum "PEPPOL Processing Type";
        SalespersonTxt: Label 'Salesperson';
        InvoiceDisAmtTxt: Label 'Invoice Discount Amount';
        PaymentDisAmtTxt: Label 'Payment Discount Amount';
        LineDisAmtTxt: Label 'Line Discount Amount';
        GLNTxt: Label 'GLN', Locked = true;
        VATTxt: Label 'VAT', Locked = true;
        MultiplyTxt: Label 'Multiply', Locked = true;
        IBANPaymentSchemeIDTxt: Label 'IBAN', Locked = true;
        LocalPaymentSchemeIDTxt: Label 'LOCAL', Locked = true;
        BICTxt: Label 'BIC', Locked = true;
        AllowanceChargeReasonCodeTxt: Label '104', Locked = true;
        AllowanceChargePaymentDiscountReasonCodeTxt: Label '95', Locked = true;
        PaymentMeansFundsTransferCodeTxt: Label '31', Locked = true;
        GTINTxt: Label '0160', Locked = true;
        UoMforPieceINUNECERec20ListIDTxt: Label 'EA', Locked = true;
#pragma warning disable AA0470
        NoUnitOfMeasureErr: Label 'The %1 %2 contains lines on which the %3 field is empty.', Comment = '1: document type, 2: document no 3 Unit of Measure Code';
#pragma warning restore AA0470
        ExportPathGreaterThan250Err: Label 'The export path is longer than 250 characters.';
        PeppolTelemetryTok: Label 'PEPPOL', Locked = true;

    /// <summary>
    /// Retrieves general invoice information from a sales header for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <param name="ID">Returns the document number.</param>
    /// <param name="IssueDate">Returns the document date in XML format.</param>
    /// <param name="InvoiceTypeCode">Returns the invoice type code.</param>
    /// <param name="InvoiceTypeCodeListID">Returns the invoice type code list identifier.</param>
    /// <param name="Note">Returns the document note.</param>
    /// <param name="TaxPointDate">Returns the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Returns the document currency code.</param>
    /// <param name="DocumentCurrencyCodeListID">Returns the currency code list identifier.</param>
    /// <param name="TaxCurrencyCode">Returns the tax currency code.</param>
    /// <param name="TaxCurrencyCodeListID">Returns the tax currency code list identifier.</param>
    /// <param name="AccountingCost">Returns the accounting cost reference.</param>
    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)
    var
        GLSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KOS', GetPeppolTelemetryTok(), Enum::"Feature Uptake Status"::Used);

        ID := SalesHeader."No.";

        IssueDate := Format(SalesHeader."Document Date", 0, 9);
        InvoiceTypeCode := GetInvoiceTypeCode();
        InvoiceTypeCodeListID := GetUNCL1001ListID();
        Note := '';

        GLSetup.Get();
        TaxPointDate := '';
        DocumentCurrencyCode := GetSalesDocCurrencyCode(SalesHeader);
        DocumentCurrencyCodeListID := GetISO4217ListID();
        TaxCurrencyCode := DocumentCurrencyCode;
        TaxCurrencyCodeListID := GetISO4217ListID();
        AccountingCost := '';

        OnAfterGetGeneralInfoProcedure(SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
    end;

    /// <summary>
    /// Retrieves general invoice information from a sales header for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <param name="ID">Returns the document number.</param>
    /// <param name="IssueDate">Returns the document date in XML format.</param>
    /// <param name="InvoiceTypeCode">Returns the invoice type code.</param>
    /// <param name="Note">Returns the document note.</param>
    /// <param name="TaxPointDate">Returns the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Returns the document currency code.</param>
    /// <param name="AccountingCost">Returns the accounting cost reference.</param>
    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
        ID := SalesHeader."No.";
        IssueDate := Format(SalesHeader."Document Date", 0, 9);
        InvoiceTypeCode := GetInvoiceTypeCode();
        Note := '';
        TaxPointDate := '';
        DocumentCurrencyCode := GetSalesDocCurrencyCode(SalesHeader);
        AccountingCost := '';

        OnAfterGetGeneralInfo(
          SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
    end;

    /// <summary>
    /// Retrieves the invoice period start and end dates.
    /// </summary>
    /// <param name="StartDate">Returns the invoice period start date.</param>
    /// <param name="EndDate">Returns the invoice period end date.</param>
    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        StartDate := '';
        EndDate := '';
    end;

    /// <summary>
    /// Retrieves the order reference information from a sales header.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <param name="OrderReferenceID">Returns the external document number as order reference.</param>
    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        OrderReferenceID := SalesHeader."External Document No.";

        OnAfterGetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    /// <summary>
    /// Retrieves the order reference information from a sales header for BIS format, using document number as fallback.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <param name="OrderReferenceID">Returns the external document number or the document number if external number is empty.</param>
    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        OrderReferenceID := SalesHeader."External Document No.";
        if OrderReferenceID = '' then
            OrderReferenceID := SalesHeader."No.";
    end;

    /// <summary>
    /// Retrieves the contract document reference information from a sales header.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <param name="ContractDocumentReferenceID">Returns the document number as contract reference.</param>
    /// <param name="DocumentTypeCode">Returns the document type code.</param>
    /// <param name="ContractRefDocTypeCodeListID">Returns the document type code list identifier.</param>
    /// <param name="DocumentType">Returns the document type description.</param>
    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        ContractDocumentReferenceID := SalesHeader."No.";
        DocumentTypeCode := '';
        ContractRefDocTypeCodeListID := GetUNCL1001ListID();
        DocumentType := '';

        OnAfterGetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

    /// <summary>
    /// Retrieves document attachment information for PEPPOL export including Base64 encoded content.
    /// </summary>
    /// <param name="AttachmentNumber">Specifies the attachment sequence number to retrieve.</param>
    /// <param name="DocumentAttachments">Specifies the document attachments record set.</param>
    /// <param name="Salesheader">Specifies the sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the attachment document reference identifier.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the document type description.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="Filename">Returns the attachment filename with extension.</param>
    /// <param name="MimeCode">Returns the MIME type code for the attachment.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the Base64 encoded attachment content.</param>
    /// <param name="NewProcessedDocType">Specifies the document type being processed.</param>
    procedure GetAdditionalDocRefInfo(AttachmentNumber: Integer; var DocumentAttachments: Record "Document Attachment"; Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        AdditionalDocumentReferenceID := '';
        AdditionalDocRefDocumentType := '';
        URI := '';
        MimeCode := '';
        EmbeddedDocumentBinaryObject := '';

        if DocumentAttachments.FindSet() then begin
            DocumentAttachments.Next(AttachmentNumber - 1);

            TempBlob.CreateOutStream(OutStream);
            DocumentAttachments.ExportToStream(OutStream);
            TempBlob.CreateInStream(InStream);

            Filename := DocumentAttachments."File Name" + '.' + DocumentAttachments."File Extension";
            AdditionalDocumentReferenceID := DocumentAttachments."No.";
            EmbeddedDocumentBinaryObject := Base64Convert.ToBase64(InStream);
            case DocumentAttachments."File Type" of
                "Document Attachment File Type"::"XML":
                    MimeCode := 'application/xml';
                "Document Attachment File Type"::Image:
                    if DocumentAttachments."File Extension".ToLower() = 'png' then
                        MimeCode := 'image/png'
                    else
                        if (DocumentAttachments."File Extension".ToLower() = 'jpeg') or (DocumentAttachments."File Extension".ToLower() = 'jpg') then
                            MimeCode := 'image/jpeg';
                "Document Attachment File Type"::PDF:
                    MimeCode := 'application/pdf';
                "Document Attachment File Type"::Excel:
                    MimeCode := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
                "Document Attachment File Type"::Other:
                    if DocumentAttachments."File Extension".ToLower() = 'txt' then
                        MimeCode := 'text/csv';
            end;

            // If no correct mime code can be set, we skip the attachment
            if MimeCode = '' then
                AdditionalDocumentReferenceID := '';

        end;

        OnAfterGetAdditionalDocRefInfo(
          AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, EmbeddedDocumentBinaryObject, SalesHeader, ProcessedDocType.AsInteger(), DocumentAttachments, Filename);
    end;

    /// <summary>
    /// Retrieves additional document reference information for PEPPOL export.
    /// </summary>
    /// <param name="Salesheader">Specifies the sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the document reference identifier.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the document type description.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="MimeCode">Returns the MIME type code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the Base64 encoded content.</param>
    /// <param name="NewProcessedDocType">Specifies the document type being processed.</param>
    procedure GetAdditionalDocRefInfo(Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)
    var
        DocumentAttachments: Record "Document Attachment";
        Filename: Text;
    begin
        AdditionalDocumentReferenceID := '';
        AdditionalDocRefDocumentType := '';
        URI := '';
        MimeCode := '';
        EmbeddedDocumentBinaryObject := '';

        OnAfterGetAdditionalDocRefInfo(
          AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, EmbeddedDocumentBinaryObject, SalesHeader, ProcessedDocType.AsInteger(), DocumentAttachments, Filename);
    end;

    /// <summary>
    /// Retrieves the buyer reference from a sales header.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract information from.</param>
    /// <returns>Returns the Your Reference field value as buyer reference.</returns>
    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text
    begin
        BuyerReference := SalesHeader."Your Reference";
        OnAfterGetBuyerReference(SalesHeader, BuyerReference);
    end;

    /// <summary>
    /// Generates a PDF attachment from report set in Report Selections.
    /// </summary>
    /// <param name="SalesHeader">Record "Sales Header" that contains the document information.</param>
    /// <param name="AdditionalDocumentReferenceID">Additional Document Reference ID is set to original document no.</param>
    /// <param name="AdditionalDocRefDocumentType">Document type is set to an empty string.</param>
    /// <param name="URI">URI is set to an empty string.</param>
    /// <param name="Filename">Filename generated in format 'DocumentType_DocumentNo.pdf'.</param>
    /// <param name="MimeCode">The MimeCode is set to application/pdf.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Text output parameter that contains the Base64 encoded PDF content.</param>
    procedure GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        FileNameTok: Label '%1_%2.pdf', Comment = '1: Document Type, 2: Document No', Locked = true;
        IsHandled: Boolean;
    begin
        AdditionalDocumentReferenceID := '';
        AdditionalDocRefDocumentType := '';
        URI := '';
        MimeCode := '';
        EmbeddedDocumentBinaryObject := '';
        Filename := '';

        OnBeforeGeneratePDFAttachmentAsAdditionalDocRef(SalesHeader, AdditionalDocumentReferenceID, AdditionalDocRefDocumentType, URI, MimeCode, Filename, EmbeddedDocumentBinaryObject, IsHandled);
        if IsHandled then
            exit;

        if not GeneratePDFAsTempBlob(SalesHeader, TempBlob) then
            exit;

        Filename := StrSubstNo(FileNameTok, SalesHeader."Document Type", SalesHeader."No.");
        AdditionalDocumentReferenceID := SalesHeader."No.";
        EmbeddedDocumentBinaryObject := Base64Convert.ToBase64(TempBlob.CreateInStream());
        MimeCode := 'application/pdf';
    end;

    local procedure GeneratePDFAsTempBlob(SalesHeader: Record "Sales Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceHeader.SetRange("No.", SalesHeader."No.");
                    if SalesInvoiceHeader.IsEmpty() then
                        exit(false);
                    ReportSelections.GetPdfReportForCust(TempBlob, "Report Selection Usage"::"S.Invoice", SalesInvoiceHeader, SalesHeader."Bill-to Customer No.");
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.SetRange("No.", SalesHeader."No.");
                    if SalesCrMemoHeader.IsEmpty() then
                        exit(false);
                    ReportSelections.GetPdfReportForCust(TempBlob, "Report Selection Usage"::"S.Cr.Memo", SalesCrMemoHeader, SalesHeader."Bill-to Customer No.");
                end;
        end;

        exit(TempBlob.HasValue());
    end;

    /// <summary>
    /// Retrieves the accounting supplier party information for PEPPOL export.
    /// </summary>
    /// <param name="SupplierEndpointID">Returns the supplier endpoint identifier (GLN or VAT registration number).</param>
    /// <param name="SupplierSchemeID">Returns the scheme identifier for the endpoint.</param>
    /// <param name="SupplierName">Returns the company name.</param>
    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        GetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, false);
    end;

    /// <summary>
    /// Retrieves the accounting supplier party information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SupplierEndpointID">Returns the supplier endpoint identifier (GLN or VAT registration number).</param>
    /// <param name="SupplierSchemeID">Returns the scheme identifier for the endpoint.</param>
    /// <param name="SupplierName">Returns the company name.</param>
    procedure GetAccountingSupplierPartyInfoBIS(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        GetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, true);
    end;

    local procedure GetAccountingSupplierPartyInfoByFormat(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text; IsBISBilling: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if (CompanyInfo.GLN <> '') and CompanyInfo."Use GLN in Electronic Document" then begin
            SupplierEndpointID := CompanyInfo.GLN;
            SupplierSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            SupplierEndpointID :=
              FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", IsBISBilling, false);
            SupplierSchemeID := GetVATScheme(CompanyInfo."Country/Region Code");
        end;

        SupplierName := CompanyInfo.Name;

        OnAfterGetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, IsBISBilling);
    end;

    /// <summary>
    /// Retrieves the supplier postal address information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to determine responsibility center.</param>
    /// <param name="StreetName">Returns the street name.</param>
    /// <param name="SupplierAdditionalStreetName">Returns the additional street name.</param>
    /// <param name="CityName">Returns the city name.</param>
    /// <param name="PostalZone">Returns the postal code.</param>
    /// <param name="CountrySubentity">Returns the county or region.</param>
    /// <param name="IdentificationCode">Returns the country ISO code.</param>
    /// <param name="ListID">Returns the country code list identifier.</param>
    procedure GetAccountingSupplierPartyPostalAddr(SalesHeader: Record "Sales Header"; var StreetName: Text; var SupplierAdditionalStreetName: Text; var CityName: Text; var PostalZone: Text; var CountrySubentity: Text; var IdentificationCode: Text; var ListID: Text)
    var
        CompanyInfo: Record "Company Information";
        RespCenter: Record "Responsibility Center";
    begin
        CompanyInfo.Get();
        if RespCenter.Get(SalesHeader."Responsibility Center") then begin
            CompanyInfo.Address := RespCenter.Address;
            CompanyInfo."Address 2" := RespCenter."Address 2";
            CompanyInfo.City := RespCenter.City;
            CompanyInfo."Post Code" := RespCenter."Post Code";
            CompanyInfo.County := RespCenter.County;
            CompanyInfo."Country/Region Code" := RespCenter."Country/Region Code";
            CompanyInfo."Phone No." := RespCenter."Phone No.";
            CompanyInfo."Fax No." := RespCenter."Fax No.";
        end;

        StreetName := CompanyInfo.Address;
        SupplierAdditionalStreetName := CompanyInfo."Address 2";
        CityName := CompanyInfo.City;
        PostalZone := CompanyInfo."Post Code";
        CountrySubentity := CompanyInfo.County;
        IdentificationCode := GetCountryISOCode(CompanyInfo."Country/Region Code");
        ListID := GetISO3166_1Alpha2();
    end;

    /// <summary>
    /// Retrieves the supplier tax scheme information for PEPPOL export.
    /// </summary>
    /// <param name="CompanyID">Returns the company VAT registration number.</param>
    /// <param name="CompanyIDSchemeID">Returns the VAT scheme identifier.</param>
    /// <param name="TaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyID := FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", true, true);
        CompanyIDSchemeID := GetVATScheme(CompanyInfo."Country/Region Code");
        TaxSchemeID := VATTxt;
    end;

    /// <summary>
    /// Retrieves the supplier tax scheme information for PEPPOL BIS export, excluding outside scope VAT.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line record to filter tax categories.</param>
    /// <param name="CompanyID">Returns the company VAT registration number.</param>
    /// <param name="CompanyIDSchemeID">Returns the VAT scheme identifier.</param>
    /// <param name="TaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        VATAmtLine.SetFilter("Tax Category", '<>%1', GetTaxCategoryO());
        if not VATAmtLine.IsEmpty() then
            GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        VATAmtLine.SetRange("Tax Category");
        CompanyID := DelChr(CompanyID);
        CompanyIDSchemeID := '';
    end;

    /// <summary>
    /// Retrieves the supplier legal entity information for PEPPOL export.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Returns the registered company name.</param>
    /// <param name="PartyLegalEntityCompanyID">Returns the company identifier (GLN or VAT number).</param>
    /// <param name="PartyLegalEntitySchemeID">Returns the scheme identifier.</param>
    /// <param name="SupplierRegAddrCityName">Returns the registered address city.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Returns the country ISO code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Returns the country code list identifier.</param>
    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        GetAccountingSupplierPartyLegalEntityByFormat(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
          SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, false);
    end;

    /// <summary>
    /// Retrieves the supplier legal entity information for PEPPOL BIS export.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Returns the registered company name.</param>
    /// <param name="PartyLegalEntityCompanyID">Returns the company identifier (GLN or VAT number).</param>
    /// <param name="PartyLegalEntitySchemeID">Returns the scheme identifier.</param>
    /// <param name="SupplierRegAddrCityName">Returns the registered address city.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Returns the country ISO code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Returns the country code list identifier.</param>
    procedure GetAccountingSupplierPartyLegalEntityBIS(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        GetAccountingSupplierPartyLegalEntityByFormat(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
          SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, true);
    end;

    local procedure GetAccountingSupplierPartyLegalEntityByFormat(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text; IsBISBilling: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        PartyLegalEntityRegName := CompanyInfo.Name;
        if (CompanyInfo.GLN <> '') and CompanyInfo."Use GLN in Electronic Document" then begin
            PartyLegalEntityCompanyID := CompanyInfo.GLN;
            PartyLegalEntitySchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            PartyLegalEntityCompanyID :=
              FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", IsBISBilling, false);
            PartyLegalEntitySchemeID := GetVATSchemeByFormat(CompanyInfo."Country/Region Code", IsBISBilling);
        end;

        SupplierRegAddrCityName := CompanyInfo.City;
        SupplierRegAddrCountryIdCode := GetCountryISOCode(CompanyInfo."Country/Region Code");
        SupplRegAddrCountryIdListId := GetISO3166_1Alpha2();

        OnAfterGetAccountingSupplierPartyLegalEntityByFormat(PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, IsBISBilling);
    end;

    /// <summary>
    /// Retrieves the supplier party contact information from the salesperson assigned to the document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to get salesperson information.</param>
    /// <param name="ContactID">Returns the contact identifier.</param>
    /// <param name="ContactName">Returns the salesperson name.</param>
    /// <param name="Telephone">Returns the salesperson phone number.</param>
    /// <param name="Telefax">Returns the company telex number.</param>
    /// <param name="ElectronicMail">Returns the salesperson email address.</param>
    procedure GetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    var
        CompanyInfo: Record "Company Information";
        Salesperson: Record "Salesperson/Purchaser";
    begin
        CompanyInfo.Get();
        GetSalesperson(SalesHeader, Salesperson);
        ContactID := SalespersonTxt;
        ContactName := Salesperson.Name;
        Telephone := Salesperson."Phone No.";
        Telefax := CompanyInfo."Telex No.";
        ElectronicMail := Salesperson."E-Mail";
        OnAfterGetAccountingSupplierPartyContact(SalesHeader, ContactID, ContactName, Telephone, Telefax, ElectronicMail);
    end;

    /// <summary>
    /// Retrieves the supplier party identification ID.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="PartyIdentificationID">Returns the party identification ID.</param>
    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        PartyIdentificationID := '';
        OnAfterGetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    /// <summary>
    /// Retrieves the accounting customer party information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract customer information.</param>
    /// <param name="CustomerEndpointID">Returns the customer endpoint identifier (GLN or VAT number).</param>
    /// <param name="CustomerSchemeID">Returns the scheme identifier for the endpoint.</param>
    /// <param name="CustomerPartyIdentificationID">Returns the customer party identification (GLN).</param>
    /// <param name="CustomerPartyIDSchemeID">Returns the party identification scheme.</param>
    /// <param name="CustomerName">Returns the bill-to customer name.</param>
    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        GetAccountingCustomerPartyInfoByFormat(
          SalesHeader, CustomerEndpointID, CustomerSchemeID,
          CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, false);
    end;

    /// <summary>
    /// Retrieves the accounting customer party information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract customer information.</param>
    /// <param name="CustomerEndpointID">Returns the customer endpoint identifier (GLN or VAT number).</param>
    /// <param name="CustomerSchemeID">Returns the scheme identifier for the endpoint.</param>
    /// <param name="CustomerPartyIdentificationID">Returns the customer party identification (GLN).</param>
    /// <param name="CustomerPartyIDSchemeID">Returns the party identification scheme.</param>
    /// <param name="CustomerName">Returns the bill-to customer name.</param>
    procedure GetAccountingCustomerPartyInfoBIS(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        GetAccountingCustomerPartyInfoByFormat(
          SalesHeader, CustomerEndpointID, CustomerSchemeID,
          CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, true);
    end;

    local procedure GetAccountingCustomerPartyInfoByFormat(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text; IsBISBilling: Boolean)
    var
        Cust: Record Customer;
    begin
        Cust.Get(SalesHeader."Bill-to Customer No.");
        if (Cust.GLN <> '') and Cust."Use GLN in Electronic Document" then begin
            CustomerEndpointID := Cust.GLN;
            CustomerSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        end else begin
            CustomerEndpointID :=
              FormatVATRegistrationNo(
                SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, false);
            CustomerSchemeID := GetVATScheme(SalesHeader."Bill-to Country/Region Code");
        end;

        CustomerPartyIdentificationID := Cust.GLN;
        CustomerPartyIDSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
        CustomerName := SalesHeader."Bill-to Name";
        OnAfterGetAccountingCustomerPartyInfoByFormat(SalesHeader, CustomerEndpointID, CustomerSchemeID, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, IsBISBilling);
    end;

    /// <summary>
    /// Retrieves the customer postal address information from the bill-to address.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract address information.</param>
    /// <param name="CustomerStreetName">Returns the bill-to street address.</param>
    /// <param name="CustomerAdditionalStreetName">Returns the bill-to address line 2.</param>
    /// <param name="CustomerCityName">Returns the bill-to city.</param>
    /// <param name="CustomerPostalZone">Returns the bill-to post code.</param>
    /// <param name="CustomerCountrySubentity">Returns the bill-to county.</param>
    /// <param name="CustomerIdentificationCode">Returns the country ISO code.</param>
    /// <param name="CustomerListID">Returns the country code list identifier.</param>
    procedure GetAccountingCustomerPartyPostalAddr(SalesHeader: Record "Sales Header"; var CustomerStreetName: Text; var CustomerAdditionalStreetName: Text; var CustomerCityName: Text; var CustomerPostalZone: Text; var CustomerCountrySubentity: Text; var CustomerIdentificationCode: Text; var CustomerListID: Text)
    begin
        CustomerStreetName := SalesHeader."Bill-to Address";
        CustomerAdditionalStreetName := SalesHeader."Bill-to Address 2";
        CustomerCityName := SalesHeader."Bill-to City";
        CustomerPostalZone := SalesHeader."Bill-to Post Code";
        CustomerCountrySubentity := SalesHeader."Bill-to County";
        CustomerIdentificationCode := GetCountryISOCode(SalesHeader."Bill-to Country/Region Code");
        CustomerListID := GetISO3166_1Alpha2();
    end;

    /// <summary>
    /// Retrieves the customer tax scheme information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract tax information.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Returns the customer VAT registration number.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Returns the VAT scheme identifier.</param>
    /// <param name="CustTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        GetAccountingCustomerPartyTaxSchemeByFormat(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, false);
    end;

    /// <summary>
    /// Retrieves the customer tax scheme information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract tax information.</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Returns the customer VAT registration number.</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Returns the VAT scheme identifier.</param>
    /// <param name="CustTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAccountingCustomerPartyTaxSchemeBIS(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        GetAccountingCustomerPartyTaxSchemeByFormat(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, true);
    end;

    /// <summary>
    /// Gets the accounting customer party tax scheme fields values
    /// </summary>
    /// <param name="SalesHeader">The sales header used for PEPPOL file creation</param>
    /// <param name="CustPartyTaxSchemeCompanyID">Return value: The customer party tax scheme company ID</param>
    /// <param name="CustPartyTaxSchemeCompIDSchID">Return value: The customer company ID's scheme ID</param>
    /// <param name="CustTaxSchemeID">Return value: The customer tax scheme ID</param>
    /// <param name="TempVATAmountLine">The temporary VAT amount line used for PEPPOL file creation</param>
    procedure GetAccountingCustomerPartyTaxSchemeBIS30(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine.SetFilter("Tax Category", '<>%1', GetTaxCategoryO());
        if not TempVATAmountLine.IsEmpty() then
            GetAccountingCustomerPartyTaxSchemeByFormat(SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, true);
        TempVATAmountLine.SetRange("Tax Category");
    end;

    local procedure GetAccountingCustomerPartyTaxSchemeByFormat(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text; IsBISBilling: Boolean)
    begin
        CustPartyTaxSchemeCompanyID :=
          FormatVATRegistrationNo(
            SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, true);
        if IsBISBilling then
            CustPartyTaxSchemeCompIDSchID := ''
        else
            CustPartyTaxSchemeCompIDSchID := GetVATSchemeByFormat(SalesHeader."Bill-to Country/Region Code", false);
        CustTaxSchemeID := VATTxt;
    end;

    /// <summary>
    /// Retrieves the customer legal entity information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract customer information.</param>
    /// <param name="CustPartyLegalEntityRegName">Returns the customer registered name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Returns the customer company identifier.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Returns the company ID scheme identifier.</param>
    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        GetAccountingCustomerPartyLegalEntityByFormat(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, false);
    end;

    /// <summary>
    /// Retrieves the customer legal entity information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract customer information.</param>
    /// <param name="CustPartyLegalEntityRegName">Returns the customer registered name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Returns the customer company identifier.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Returns the company ID scheme identifier.</param>
    procedure GetAccountingCustomerPartyLegalEntityBIS(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        GetAccountingCustomerPartyLegalEntityByFormat(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, true);
    end;

    local procedure GetAccountingCustomerPartyLegalEntityByFormat(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text; IsBISBilling: Boolean)
    var
        Customer: Record Customer;
    begin
        if Customer.Get(SalesHeader."Bill-to Customer No.") then begin
            CustPartyLegalEntityRegName := Customer.Name;
            if (Customer.GLN <> '') and Customer."Use GLN in Electronic Document" then begin
                CustPartyLegalEntityCompanyID := Customer.GLN;
                CustPartyLegalEntityIDSchemeID := GetGLNSchemeIDByFormat(IsBISBilling);
            end else begin
                CustPartyLegalEntityCompanyID :=
                  FormatVATRegistrationNo(
                    SalesHeader.GetCustomerVATRegistrationNumber(), SalesHeader."Bill-to Country/Region Code", IsBISBilling, false);
                CustPartyLegalEntityIDSchemeID := GetVATSchemeByFormat(SalesHeader."Bill-to Country/Region Code", IsBISBilling);
            end;
        end;
        OnAfterGetAccountingCustomerPartyLegalEntityByFormat(SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, IsBISBilling);
    end;

    /// <summary>
    /// Retrieves the customer party contact information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract contact information.</param>
    /// <param name="CustContactID">Returns the customer reference identifier.</param>
    /// <param name="CustContactName">Returns the bill-to contact name.</param>
    /// <param name="CustContactTelephone">Returns the customer phone number.</param>
    /// <param name="CustContactTelefax">Returns the customer telex number.</param>
    /// <param name="CustContactElectronicMail">Returns the customer email address.</param>
    procedure GetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    var
        Customer: Record Customer;
    begin
        CustContactID := SalesHeader."Your Reference";
        if SalesHeader."Bill-to Contact" <> '' then
            CustContactName := SalesHeader."Bill-to Contact"
        else
            CustContactName := SalesHeader."Bill-to Name";

        if Customer.Get(SalesHeader."Bill-to Customer No.") then begin
            CustContactTelephone := Customer."Phone No.";
            CustContactTelefax := Customer."Telex No.";
            CustContactElectronicMail := Customer."E-Mail";
        end;

        OnAfterGetAccountingCustomerPartyContact(SalesHeader, Customer, CustContactID, CustContactName, CustContactTelephone, CustContactTelefax, CustContactElectronicMail);
    end;

    /// <summary>
    /// Retrieves the payee party information for PEPPOL export.
    /// </summary>
    /// <param name="PayeePartyID">Returns the payee party identifier (GLN).</param>
    /// <param name="PayeePartyIDSchemeID">Returns the party ID scheme identifier.</param>
    /// <param name="PayeePartyNameName">Returns the company name.</param>
    /// <param name="PayeePartyLegalEntityCompanyID">Returns the company VAT registration number.</param>
    /// <param name="PayeePartyLegalCompIDSchemeID">Returns the VAT scheme identifier.</param>
    procedure GetPayeePartyInfo(var PayeePartyID: Text; var PayeePartyIDSchemeID: Text; var PayeePartyNameName: Text; var PayeePartyLegalEntityCompanyID: Text; var PayeePartyLegalCompIDSchemeID: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        PayeePartyID := CompanyInfo.GLN;
        PayeePartyIDSchemeID := GLNTxt;
        PayeePartyNameName := CompanyInfo.Name;
        PayeePartyLegalEntityCompanyID := CompanyInfo.GetVATRegistrationNumber();
        PayeePartyLegalCompIDSchemeID := GetVATScheme(CompanyInfo."Country/Region Code");
    end;

    /// <summary>
    /// Retrieves the tax representative party information for PEPPOL export.
    /// </summary>
    /// <param name="TaxRepPartyNameName">Returns the tax representative party name.</param>
    /// <param name="PayeePartyTaxSchemeCompanyID">Returns the tax scheme company identifier.</param>
    /// <param name="PayeePartyTaxSchCompIDSchemeID">Returns the company ID scheme identifier.</param>
    /// <param name="PayeePartyTaxSchemeTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        TaxRepPartyNameName := '';
        PayeePartyTaxSchemeCompanyID := '';
        PayeePartyTaxSchCompIDSchemeID := '';
        PayeePartyTaxSchemeTaxSchemeID := '';
    end;

    /// <summary>
    /// Retrieves the delivery information for PEPPOL export.
    /// </summary>
    /// <param name="ActualDeliveryDate">Returns the actual delivery date.</param>
    /// <param name="DeliveryID">Returns the delivery identifier.</param>
    /// <param name="DeliveryIDSchemeID">Returns the delivery ID scheme identifier.</param>
    procedure GetDeliveryInfo(var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        ActualDeliveryDate := '';
        DeliveryID := '';
        DeliveryIDSchemeID := '';
    end;

    /// <summary>
    /// Retrieves the delivery information with GLN for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract delivery information.</param>
    /// <param name="ActualDeliveryDate">Returns the shipment date.</param>
    /// <param name="DeliveryID">Returns the delivery GLN.</param>
    /// <param name="DeliveryIDSchemeID">Returns the GLN scheme identifier.</param>
    procedure GetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        ActualDeliveryDate := Format(SalesHeader."Shipment Date", 0, 9);

        DeliveryID := GetGLNForHeader(SalesHeader);

        if DeliveryID <> '' then
            DeliveryIDSchemeID := '0088'
        else
            DeliveryIDSchemeID := '';
        OnAfterGetGLNDeliveryInfo(SalesHeader, ActualDeliveryDate, DeliveryID, DeliveryIDSchemeID);
    end;

    /// <summary>
    /// Retrieves the GLN for the sales header from ship-to address or customer.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract the GLN from.</param>
    /// <returns>Returns the GLN from ship-to address if available, otherwise from customer.</returns>
    procedure GetGLNForHeader(SalesHeader: Record "Sales Header"): Code[13]
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        if ShipToAddress.Get(SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code") then
            if ShipToAddress.GLN <> '' then
                exit(ShipToAddress.GLN);
        if Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit(Customer.GLN);
        exit('');
    end;

    /// <summary>
    /// Retrieves the delivery address information from the ship-to address.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract delivery address.</param>
    /// <param name="DeliveryStreetName">Returns the ship-to street address.</param>
    /// <param name="DeliveryAdditionalStreetName">Returns the ship-to address line 2.</param>
    /// <param name="DeliveryCityName">Returns the ship-to city.</param>
    /// <param name="DeliveryPostalZone">Returns the ship-to post code.</param>
    /// <param name="DeliveryCountrySubentity">Returns the ship-to county.</param>
    /// <param name="DeliveryCountryIdCode">Returns the country ISO code.</param>
    /// <param name="DeliveryCountryListID">Returns the country code list identifier.</param>
    procedure GetDeliveryAddress(SalesHeader: Record "Sales Header"; var DeliveryStreetName: Text; var DeliveryAdditionalStreetName: Text; var DeliveryCityName: Text; var DeliveryPostalZone: Text; var DeliveryCountrySubentity: Text; var DeliveryCountryIdCode: Text; var DeliveryCountryListID: Text)
    begin
        DeliveryStreetName := SalesHeader."Ship-to Address";
        DeliveryAdditionalStreetName := SalesHeader."Ship-to Address 2";
        DeliveryCityName := SalesHeader."Ship-to City";
        DeliveryPostalZone := SalesHeader."Ship-to Post Code";
        DeliveryCountrySubentity := SalesHeader."Ship-to County";
        DeliveryCountryIdCode := GetCountryISOCode(SalesHeader."Ship-to Country/Region Code");
        DeliveryCountryListID := GetISO3166_1Alpha2();
    end;

    /// <summary>
    /// Retrieves the payment means information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract payment information.</param>
    /// <param name="PaymentMeansCode">Returns the payment means code.</param>
    /// <param name="PaymentMeansListID">Returns the payment means list identifier.</param>
    /// <param name="PaymentDueDate">Returns the payment due date.</param>
    /// <param name="PaymentChannelCode">Returns the payment channel code.</param>
    /// <param name="PaymentID">Returns the payment identifier.</param>
    /// <param name="PrimaryAccountNumberID">Returns the primary account number.</param>
    /// <param name="NetworkID">Returns the network identifier.</param>
    procedure GetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)
    begin
        PaymentMeansCode := PaymentMeansFundsTransferCodeTxt;
        PaymentMeansListID := GetUNCL4461ListID();
        PaymentDueDate := Format(SalesHeader."Due Date", 0, 9);
        PaymentChannelCode := '';
        PaymentID := '';
        PrimaryAccountNumberID := '';
        NetworkID := '';
        OnAfterGetPaymentMeansInfo(SalesHeader, PaymentMeansCode, PaymentMeansListID, PaymentDueDate, PaymentChannelCode, PaymentID, PrimaryAccountNumberID, NetworkID);
    end;

    /// <summary>
    /// Retrieves the payee financial account information for PEPPOL export.
    /// </summary>
    /// <param name="PayeeFinancialAccountID">Returns the payee bank account number or IBAN.</param>
    /// <param name="PaymentMeansSchemeID">Returns the payment scheme identifier (IBAN or LOCAL).</param>
    /// <param name="FinancialInstitutionBranchID">Returns the bank branch number.</param>
    /// <param name="FinancialInstitutionID">Returns the SWIFT code.</param>
    /// <param name="FinancialInstitutionSchemeID">Returns the financial institution scheme (BIC).</param>
    /// <param name="FinancialInstitutionName">Returns the bank name.</param>
    procedure GetPaymentMeansPayeeFinancialAcc(var PayeeFinancialAccountID: Text; var PaymentMeansSchemeID: Text; var FinancialInstitutionBranchID: Text; var FinancialInstitutionID: Text; var FinancialInstitutionSchemeID: Text; var FinancialInstitutionName: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if CompanyInfo.IBAN <> '' then begin
            PayeeFinancialAccountID := DelChr(CompanyInfo.IBAN, '=', ' ');
            PaymentMeansSchemeID := IBANPaymentSchemeIDTxt;
        end else
            if CompanyInfo."Bank Account No." <> '' then begin
                PayeeFinancialAccountID := CompanyInfo."Bank Account No.";
                PaymentMeansSchemeID := LocalPaymentSchemeIDTxt;
            end;

        FinancialInstitutionBranchID := CompanyInfo."Bank Branch No.";
        FinancialInstitutionID := DelChr(CompanyInfo."SWIFT Code", '=', ' ');
        FinancialInstitutionSchemeID := BICTxt;
        FinancialInstitutionName := CompanyInfo."Bank Name";

        OnAfterGetPaymentMeansPayeeFinancialAcc(CompanyInfo, PayeeFinancialAccountID, PaymentMeansSchemeID);
    end;

    /// <summary>
    /// Retrieves the payee financial account information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="PayeeFinancialAccountID">Returns the payee bank account number or IBAN.</param>
    /// <param name="FinancialInstitutionBranchID">Returns the bank branch number.</param>
    procedure GetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if CompanyInfo.IBAN <> '' then
            PayeeFinancialAccountID := DelChr(CompanyInfo.IBAN, '=', ' ')
        else
            if CompanyInfo."Bank Account No." <> '' then
                PayeeFinancialAccountID := CompanyInfo."Bank Account No.";
        FinancialInstitutionBranchID := CompanyInfo."Bank Branch No.";

        OnAfterGetPaymentMeansPayeeFinancialAccBIS(SalesHeader, PayeeFinancialAccountID, FinancialInstitutionBranchID);
    end;


    /// <summary>
    /// Retrieves the financial institution address information for PEPPOL export.
    /// </summary>
    /// <param name="FinancialInstitutionStreetName">Returns the financial institution street name.</param>
    /// <param name="AdditionalStreetName">Returns the additional street name.</param>
    /// <param name="FinancialInstitutionCityName">Returns the city name.</param>
    /// <param name="FinancialInstitutionPostalZone">Returns the postal code.</param>
    /// <param name="FinancialInstCountrySubentity">Returns the country subentity.</param>
    /// <param name="FinancialInstCountryIdCode">Returns the country identification code.</param>
    /// <param name="FinancialInstCountryListID">Returns the country list identifier.</param>
    procedure GetPaymentMeansFinancialInstitutionAddr(var FinancialInstitutionStreetName: Text; var AdditionalStreetName: Text; var FinancialInstitutionCityName: Text; var FinancialInstitutionPostalZone: Text; var FinancialInstCountrySubentity: Text; var FinancialInstCountryIdCode: Text; var FinancialInstCountryListID: Text)
    begin
        FinancialInstitutionStreetName := '';
        AdditionalStreetName := '';
        FinancialInstitutionCityName := '';
        FinancialInstitutionPostalZone := '';
        FinancialInstCountrySubentity := '';
        FinancialInstCountryIdCode := '';
        FinancialInstCountryListID := '';
    end;

    /// <summary>
    /// Retrieves the payment terms information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract payment terms.</param>
    /// <param name="PaymentTermsNote">Returns the payment terms description.</param>
    procedure GetPaymentTermsInfo(SalesHeader: Record "Sales Header"; var PaymentTermsNote: Text)
    var
        PmtTerms: Record "Payment Terms";
    begin
        if SalesHeader."Payment Terms Code" = '' then
            PmtTerms.Init()
        else begin
            PmtTerms.Get(SalesHeader."Payment Terms Code");
            PmtTerms.TranslateDescription(PmtTerms, SalesHeader."Language Code");
        end;

        PaymentTermsNote := PmtTerms.Description;
    end;

    /// <summary>
    /// Retrieves the allowance charge information for invoice discount.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line with discount information.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ChargeIndicator">Returns false for allowance.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the charge list identifier.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance charge reason text.</param>
    /// <param name="Amount">Returns the invoice discount amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the currency code.</param>
    /// <param name="TaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme identifier.</param>
    /// <param name="Percent">Returns the VAT percentage.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAllowanceChargeInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        if VATAmtLine."Invoice Discount Amount" = 0 then begin
            ChargeIndicator := '';
            exit;
        end;

        ChargeIndicator := 'false';
        AllowanceChargeReasonCode := AllowanceChargeReasonCodeTxt;
        AllowanceChargeListID := GetUNCL4465ListID();
        AllowanceChargeReason := InvoiceDisAmtTxt;
        Amount := Format(VATAmtLine."Invoice Discount Amount", 0, 9);
        AllowanceChargeCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        TaxCategoryID := VATAmtLine."Tax Category";
        TaxCategorySchemeID := '';
        Percent := Format(VATAmtLine."VAT %", 0, 9);
        AllowanceChargeTaxSchemeID := VATTxt;
    end;

    /// <summary>
    /// Retrieves the allowance charge information for payment discount.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line with payment discount information.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ChargeIndicator">Returns false for allowance.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the payment discount reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the charge list identifier.</param>
    /// <param name="AllowanceChargeReason">Returns the payment discount reason text.</param>
    /// <param name="Amount">Returns the payment discount amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the currency code.</param>
    /// <param name="TaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme identifier.</param>
    /// <param name="Percent">Returns the VAT percentage.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAllowanceChargeInfoPaymentDiscount(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        if VATAmtLine."Pmt. Discount Amount" = 0 then begin
            ChargeIndicator := '';
            exit;
        end;

        ChargeIndicator := 'false';
        AllowanceChargeReasonCode := AllowanceChargePaymentDiscountReasonCodeTxt;
        AllowanceChargeListID := GetUNCL4465ListID();
        AllowanceChargeReason := PaymentDisAmtTxt;
        Amount := Format(VATAmtLine."Pmt. Discount Amount", 0, 9);
        AllowanceChargeCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        TaxCategoryID := VATAmtLine."Tax Category";
        TaxCategorySchemeID := '';
        Percent := Format(VATAmtLine."VAT %", 0, 9);
        AllowanceChargeTaxSchemeID := VATTxt;
    end;

    /// <summary>
    /// Retrieves the allowance charge information for PEPPOL BIS export, clearing percent for outside scope VAT.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line with discount information.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ChargeIndicator">Returns false for allowance.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the charge list identifier.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance charge reason text.</param>
    /// <param name="Amount">Returns the invoice discount amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the currency code.</param>
    /// <param name="TaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme identifier.</param>
    /// <param name="Percent">Returns the VAT percentage or empty for outside scope VAT.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        GetAllowanceChargeInfo(
          VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason,
          Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
        if TaxCategoryID = GetTaxCategoryO() then
            Percent := '';
    end;

    /// <summary>
    /// Retrieves the tax exchange rate information when document currency differs from local currency.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record to extract currency information.</param>
    /// <param name="SourceCurrencyCode">Returns the document currency code.</param>
    /// <param name="SourceCurrencyCodeListID">Returns the source currency code list identifier.</param>
    /// <param name="TargetCurrencyCode">Returns the local currency code.</param>
    /// <param name="TargetCurrencyCodeListID">Returns the target currency code list identifier.</param>
    /// <param name="CalculationRate">Returns the currency exchange rate factor.</param>
    /// <param name="MathematicOperatorCode">Returns the mathematic operator (Multiply).</param>
    /// <param name="Date">Returns the posting date.</param>
    procedure GetTaxExchangeRateInfo(SalesHeader: Record "Sales Header"; var SourceCurrencyCode: Text; var SourceCurrencyCodeListID: Text; var TargetCurrencyCode: Text; var TargetCurrencyCodeListID: Text; var CalculationRate: Text; var MathematicOperatorCode: Text; var Date: Text)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."LCY Code" = GetSalesDocCurrencyCode(SalesHeader) then
            exit;

        SourceCurrencyCode := GetSalesDocCurrencyCode(SalesHeader);
        SourceCurrencyCodeListID := GetISO4217ListID();
        TargetCurrencyCode := GLSetup."LCY Code";
        TargetCurrencyCodeListID := GetISO4217ListID();
        CalculationRate := Format(SalesHeader."Currency Factor", 0, 9);
        MathematicOperatorCode := MultiplyTxt;
        Date := Format(SalesHeader."Posting Date", 0, 9);
    end;

    /// <summary>
    /// Retrieves the tax total information from VAT amount lines.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line record to calculate totals.</param>
    /// <param name="TaxAmount">Returns the total VAT amount.</param>
    /// <param name="TaxTotalCurrencyID">Returns the currency code.</param>
    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
        VATAmtLine.CalcSums(VATAmtLine."VAT Amount");
        TaxAmount := Format(VATAmtLine."VAT Amount", 0, 9);
        TaxTotalCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        OnAfterGetTaxTotalInfo(SalesHeader, VATAmtLine, TaxAmount);
    end;

    /// <summary>
    /// Retrieves the tax subtotal information for a VAT amount line.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TaxableAmount">Returns the VAT base amount minus payment discount.</param>
    /// <param name="TaxAmountCurrencyID">Returns the currency code for taxable amount.</param>
    /// <param name="SubtotalTaxAmount">Returns the VAT amount.</param>
    /// <param name="TaxSubtotalCurrencyID">Returns the currency code for subtotal.</param>
    /// <param name="TransactionCurrencyTaxAmount">Returns the tax amount in local currency.</param>
    /// <param name="TransCurrTaxAmtCurrencyID">Returns the local currency code.</param>
    /// <param name="TaxTotalTaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="schemeID">Returns the tax scheme identifier.</param>
    /// <param name="TaxCategoryPercent">Returns the VAT percentage.</param>
    /// <param name="TaxTotalTaxSchemeID">Returns the tax scheme identifier.</param>
    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        TaxableAmount := Format(VATAmtLine."VAT Base" - VATAmtLine."Pmt. Discount Amount", 0, 9);
        TaxAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        SubtotalTaxAmount := Format(VATAmtLine."VAT Amount", 0, 9);
        TaxSubtotalCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        GLSetup.Get();
        if GLSetup."LCY Code" <> GetSalesDocCurrencyCode(SalesHeader) then begin
            TransactionCurrencyTaxAmount :=
              Format(
                VATAmtLine.GetAmountLCY(
                  SalesHeader."Posting Date",
                  GetSalesDocCurrencyCode(SalesHeader),
                  SalesHeader."Currency Factor"), 0, 9);
            TransCurrTaxAmtCurrencyID := GLSetup."LCY Code";
        end;
        TaxTotalTaxCategoryID := VATAmtLine."Tax Category";
        schemeID := '';
        TaxCategoryPercent := Format(VATAmtLine."VAT %", 0, 9);
        TaxTotalTaxSchemeID := VATTxt;

        OnAfterGetTaxSubtotalInfo(
          VATAmtLine, SalesHeader, TaxableAmount, SubtotalTaxAmount,
          TransactionCurrencyTaxAmount, TaxTotalTaxCategoryID, schemeID,
          TaxCategoryPercent, TaxTotalTaxSchemeID);
    end;

    /// <summary>
    /// Retrieves the tax total information in local currency when document uses foreign currency.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TaxAmount">Returns the total VAT amount in local currency.</param>
    /// <param name="TaxCurrencyID">Returns the tax currency identifier.</param>
    /// <param name="TaxTotalCurrencyID">Returns the tax total currency identifier.</param>
    procedure GetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = GetSalesDocCurrencyCode(SalesHeader) then
            exit;

        TaxCurrencyID := '';
        TaxTotalCurrencyID := '';
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
            SalesHeader."Document Type"::"Credit Memo":
                VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        end;
        VATEntry.SetRange("Document No.", SalesHeader."No.");
        VATEntry.SetRange("Posting Date", SalesHeader."Posting Date");
        VATEntry.CalcSums(Amount);
        TaxAmount := Format(Abs(VATEntry.Amount), 0, 9);

        OnAfterGetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);
    end;

    /// <summary>
    /// Retrieves the legal monetary totals including line extension, tax amounts, and payable amount.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TempSalesLine">Specifies the temporary sales line for invoice rounding.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line record for totals calculation.</param>
    /// <param name="LineExtensionAmount">Returns the total line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Returns the currency code.</param>
    /// <param name="TaxExclusiveAmount">Returns the amount excluding VAT.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Returns the currency code for tax exclusive amount.</param>
    /// <param name="TaxInclusiveAmount">Returns the amount including VAT.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Returns the currency code for tax inclusive amount.</param>
    /// <param name="AllowanceTotalAmount">Returns the total allowance amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Returns the currency code for allowance.</param>
    /// <param name="ChargeTotalAmount">Returns the total charge amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Returns the currency code for charges.</param>
    /// <param name="PrepaidAmount">Returns the prepaid amount.</param>
    /// <param name="PrepaidCurrencyID">Returns the currency code for prepaid amount.</param>
    /// <param name="PayableRoundingAmount">Returns the rounding amount.</param>
    /// <param name="PayableRndingAmountCurrencyID">Returns the currency code for rounding.</param>
    /// <param name="PayableAmount">Returns the total payable amount.</param>
    /// <param name="PayableAmountCurrencyID">Returns the currency code for payable amount.</param>
    procedure GetLegalMonetaryInfo(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)
    begin
        VATAmtLine.Reset();
        VATAmtLine.CalcSums("Line Amount", "VAT Base", "Amount Including VAT", "Invoice Discount Amount");

        GetLegalMonetaryDocAmounts(
                SalesHeader, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID,
                TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID,
                AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID);

        PrepaidAmount := '0.00';
        PrepaidCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        if TempSalesLine."Line No." = 0 then begin
            PayableRoundingAmount :=
              Format(VATAmtLine."Amount Including VAT" - Round(VATAmtLine."Amount Including VAT", 0.01), 0, 9);
            PayableRndingAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

            PayableAmount := Format(Round(VATAmtLine."Amount Including VAT" - VATAmtLine."Pmt. Discount Amount", 0.01), 0, 9);
            PayableAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        end else begin
            PayableRoundingAmount := Format(TempSalesLine."Amount Including VAT", 0, 9);
            PayableRndingAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

            PayableAmount := Format(Round(VATAmtLine."Amount Including VAT" + TempSalesLine."Amount Including VAT" - VATAmtLine."Pmt. Discount Amount", 0.01), 0, 9);
            PayableAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        end;

        OnAfterGetLegalMonetaryInfoWithInvRounding(
          SalesHeader, TempSalesLine, VATAmtLine, LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount,
          AllowanceTotalAmount, ChargeTotalAmount, PrepaidAmount, PayableRoundingAmount, PayableAmount);
    end;


    /// <summary>
    /// Retrieves the document-level monetary amounts for legal monetary totals.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line record with calculated totals.</param>
    /// <param name="LineExtensionAmount">Returns the line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Returns the currency code.</param>
    /// <param name="TaxExclusiveAmount">Returns the tax exclusive amount.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Returns the currency code for tax exclusive amount.</param>
    /// <param name="TaxInclusiveAmount">Returns the tax inclusive amount.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Returns the currency code for tax inclusive amount.</param>
    /// <param name="AllowanceTotalAmount">Returns the allowance total amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Returns the currency code for allowance.</param>
    /// <param name="ChargeTotalAmount">Returns the charge total amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Returns the currency code for charges.</param>
    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)
    begin
        LineExtensionAmount := Format(Round(VATAmtLine."VAT Base", 0.01) + Round(VATAmtLine."Invoice Discount Amount", 0.01), 0, 9);
        LegalMonetaryTotalCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        TaxExclusiveAmount := Format(Round(VATAmtLine."VAT Base" - VATAmtLine."Pmt. Discount Amount", 0.01), 0, 9);
        TaxExclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        TaxInclusiveAmount := Format(Round(VATAmtLine."Amount Including VAT" - VATAmtLine."Pmt. Discount Amount", 0.01, '>'), 0, 9); // Should be two decimal places
        TaxInclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        AllowanceTotalAmount := Format(Round(VATAmtLine."Invoice Discount Amount" + VATAmtLine."Pmt. Discount Amount", 0.01), 0, 9);
        AllowanceTotalAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        TaxInclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        ChargeTotalAmount := '';
        ChargeTotalAmountCurrencyID := '';
    end;

    /// <summary>
    /// Retrieves the general line information for PEPPOL export.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvoiceLineID">Returns the line number.</param>
    /// <param name="InvoiceLineNote">Returns the line type as note.</param>
    /// <param name="InvoicedQuantity">Returns the quantity.</param>
    /// <param name="InvoiceLineExtensionAmount">Returns the line amount.</param>
    /// <param name="LineExtensionAmountCurrencyID">Returns the currency code.</param>
    /// <param name="InvoiceLineAccountingCost">Returns the accounting cost reference.</param>
    procedure GetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)
    var
        SalesLineLineAmount: Decimal;
    begin
        InvoiceLineID := Format(SalesLine."Line No.", 0, 9);
        InvoiceLineNote := DelChr(Format(SalesLine.Type), '<>');
        InvoicedQuantity := Format(SalesLine.Quantity, 0, 9);
        SalesLineLineAmount := SalesLine."Line Amount";
        InvoiceLineExtensionAmount := Format(SalesLineLineAmount, 0, 9);
        LineExtensionAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        InvoiceLineAccountingCost := '';

        OnAfterGetLineGeneralInfo(
          SalesLine, SalesHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity,
          InvoiceLineExtensionAmount, InvoiceLineAccountingCost);
    end;

    /// <summary>
    /// Retrieves the unit of measure code information for a sales line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="unitCode">Returns the international standard unit code.</param>
    /// <param name="unitCodeListID">Returns the unit code list identifier.</param>
    procedure GetLineUnitCodeInfo(SalesLine: Record "Sales Line"; var unitCode: Text; var unitCodeListID: Text)
    var
        UOM: Record "Unit of Measure";
    begin
        unitCode := '';
        unitCodeListID := GetUNECERec20ListID();

        if SalesLine.Quantity = 0 then begin
            unitCode := UoMforPieceINUNECERec20ListIDTxt; // unitCode is required
            exit;
        end;

        case SalesLine.Type of
            SalesLine.Type::Item, SalesLine.Type::Resource:
                if UOM.Get(SalesLine."Unit of Measure Code") then
                    unitCode := UOM."International Standard Code"
                else
                    Error(NoUnitOfMeasureErr, SalesLine."Document Type", SalesLine."Document No.", SalesLine.FieldCaption("Unit of Measure Code"));
            SalesLine.Type::"G/L Account", SalesLine.Type::"Fixed Asset", SalesLine.Type::"Charge (Item)":
                if UOM.Get(SalesLine."Unit of Measure Code") then
                    unitCode := UOM."International Standard Code"
                else
                    unitCode := UoMforPieceINUNECERec20ListIDTxt;
        end;
    end;

    /// <summary>
    /// Retrieves the invoice period information for a line.
    /// </summary>
    /// <param name="InvLineInvoicePeriodStartDate">Returns the invoice line period start date.</param>
    /// <param name="InvLineInvoicePeriodEndDate">Returns the invoice line period end date.</param>
    procedure GetLineInvoicePeriodInfo(var InvLineInvoicePeriodStartDate: Text; var InvLineInvoicePeriodEndDate: Text)
    begin
        InvLineInvoicePeriodStartDate := '';
        InvLineInvoicePeriodEndDate := '';
    end;

    /// <summary>
    /// Placeholder for line order reference information retrieval.
    /// </summary>
    procedure GetLineOrderLineRefInfo()
    begin
    end;

    /// <summary>
    /// Retrieves the line delivery information.
    /// </summary>
    /// <param name="InvoiceLineActualDeliveryDate">Returns the actual delivery date for the line.</param>
    /// <param name="InvoiceLineDeliveryID">Returns the delivery identifier.</param>
    /// <param name="InvoiceLineDeliveryIDSchemeID">Returns the delivery ID scheme identifier.</param>
    procedure GetLineDeliveryInfo(var InvoiceLineActualDeliveryDate: Text; var InvoiceLineDeliveryID: Text; var InvoiceLineDeliveryIDSchemeID: Text)
    begin
        InvoiceLineActualDeliveryDate := '';
        InvoiceLineDeliveryID := '';
        InvoiceLineDeliveryIDSchemeID := '';
    end;

    /// <summary>
    /// Retrieves the line delivery postal address information.
    /// </summary>
    /// <param name="InvoiceLineDeliveryStreetName">Returns the delivery street name.</param>
    /// <param name="InvLineDeliveryAddStreetName">Returns the additional delivery street name.</param>
    /// <param name="InvoiceLineDeliveryCityName">Returns the delivery city name.</param>
    /// <param name="InvoiceLineDeliveryPostalZone">Returns the delivery postal code.</param>
    /// <param name="InvLnDeliveryCountrySubentity">Returns the delivery country subentity.</param>
    /// <param name="InvLnDeliveryCountryIdCode">Returns the delivery country code.</param>
    /// <param name="InvLineDeliveryCountryListID">Returns the country list identifier.</param>
    procedure GetLineDeliveryPostalAddr(var InvoiceLineDeliveryStreetName: Text; var InvLineDeliveryAddStreetName: Text; var InvoiceLineDeliveryCityName: Text; var InvoiceLineDeliveryPostalZone: Text; var InvLnDeliveryCountrySubentity: Text; var InvLnDeliveryCountryIdCode: Text; var InvLineDeliveryCountryListID: Text)
    begin
        InvoiceLineDeliveryStreetName := '';
        InvLineDeliveryAddStreetName := '';
        InvoiceLineDeliveryCityName := '';
        InvoiceLineDeliveryPostalZone := '';
        InvLnDeliveryCountrySubentity := '';
        InvLnDeliveryCountryIdCode := '';
        InvLineDeliveryCountryListID := GetISO3166_1Alpha2();
    end;

    /// <summary>
    /// Retrieves the delivery party name.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="DeliveryPartyName">Returns the delivery party name.</param>
    procedure GetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyName: Text)
    begin
        DeliveryPartyName := '';
        OnAfterGetDeliveryPartyName(SalesHeader, DeliveryPartyName);
    end;

    /// <summary>
    /// Retrieves the line allowance charge information for line discount.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvLnAllowanceChargeIndicator">Returns false for allowance.</param>
    /// <param name="InvLnAllowanceChargeReason">Returns the line discount reason.</param>
    /// <param name="InvLnAllowanceChargeAmount">Returns the line discount amount.</param>
    /// <param name="InvLnAllowanceChargeAmtCurrID">Returns the currency code.</param>
    procedure GetLineAllowanceChargeInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvLnAllowanceChargeIndicator: Text; var InvLnAllowanceChargeReason: Text; var InvLnAllowanceChargeAmount: Text; var InvLnAllowanceChargeAmtCurrID: Text)
    begin
        InvLnAllowanceChargeIndicator := '';
        InvLnAllowanceChargeReason := '';
        InvLnAllowanceChargeAmount := '';
        InvLnAllowanceChargeAmtCurrID := '';
        if SalesLine."Line Discount Amount" = 0 then
            exit;

        InvLnAllowanceChargeIndicator := 'false';
        InvLnAllowanceChargeReason := LineDisAmtTxt;
        InvLnAllowanceChargeAmount := Format(SalesLine."Line Discount Amount", 0, 9);
        InvLnAllowanceChargeAmtCurrID := GetSalesDocCurrencyCode(SalesHeader);
    end;

    /// <summary>
    /// Retrieves the line tax total amount.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvoiceLineTaxAmount">Returns the VAT amount for the line.</param>
    /// <param name="currencyID">Returns the currency code.</param>
    procedure GetLineTaxTotal(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineTaxAmount: Text; var currencyID: Text)
    begin
        InvoiceLineTaxAmount := Format(SalesLine."Amount Including VAT" - SalesLine.Amount, 0, 9);
        currencyID := GetSalesDocCurrencyCode(SalesHeader);
    end;

    /// <summary>
    /// Retrieves the item information for a sales line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="Description">Returns the item description 2.</param>
    /// <param name="Name">Returns the item description.</param>
    /// <param name="SellersItemIdentificationID">Returns the item number.</param>
    /// <param name="StandardItemIdentificationID">Returns the item GTIN.</param>
    /// <param name="StdItemIdIDSchemeID">Returns the GTIN scheme identifier.</param>
    /// <param name="OriginCountryIdCode">Returns the country of origin code.</param>
    /// <param name="OriginCountryIdCodeListID">Returns the country code list identifier.</param>
    procedure GetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)
    var
        Item: Record Item;
    begin
        Name := SalesLine.Description;
        Description := SalesLine."Description 2";

        if (SalesLine.Type = SalesLine.Type::Item) and Item.Get(SalesLine."No.") then begin
            SellersItemIdentificationID := SalesLine."No.";
            StandardItemIdentificationID := Item.GTIN;
            StdItemIdIDSchemeID := GTINTxt;
        end else begin
            SellersItemIdentificationID := '';
            StandardItemIdentificationID := '';
            StdItemIdIDSchemeID := '';
        end;

        OriginCountryIdCode := '';
        OriginCountryIdCodeListID := '';
        if SalesLine.Type <> SalesLine.Type::" " then
            OriginCountryIdCodeListID := GetISO3166_1Alpha2();

        OnAfterGetLineItemInfo(SalesLine, Description, Name, SellersItemIdentificationID, StandardItemIdentificationID, StdItemIdIDSchemeID, OriginCountryIdCode, OriginCountryIdCodeListID);
    end;

    /// <summary>
    /// Retrieves the item commodity classification information.
    /// </summary>
    /// <param name="CommodityCode">Returns the commodity code.</param>
    /// <param name="CommodityCodeListID">Returns the commodity code list identifier.</param>
    /// <param name="ItemClassificationCode">Returns the item classification code.</param>
    /// <param name="ItemClassificationCodeListID">Returns the item classification code list identifier.</param>
    procedure GetLineItemCommodityClassficationInfo(var CommodityCode: Text; var CommodityCodeListID: Text; var ItemClassificationCode: Text; var ItemClassificationCodeListID: Text)
    begin
        CommodityCode := '';
        CommodityCodeListID := '';

        ItemClassificationCode := '';
        ItemClassificationCodeListID := '';
    end;

    /// <summary>
    /// Retrieves the classified tax category information for a sales line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="ClassifiedTaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="ItemSchemeID">Returns the item scheme identifier.</param>
    /// <param name="InvoiceLineTaxPercent">Returns the VAT percentage.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Returns the tax category scheme identifier.</param>
    procedure GetLineItemClassfiedTaxCategory(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then begin
            ClassifiedTaxCategoryID := VATPostingSetup."Tax Category";
            InvoiceLineTaxPercent := Format(SalesLine."VAT %", 0, 9);
        end;

        if ClassifiedTaxCategoryID = '' then begin
            ClassifiedTaxCategoryID := GetTaxCategoryE();
            InvoiceLineTaxPercent := '0';
        end;

        ItemSchemeID := '';
        ClassifiedTaxCategorySchemeID := VATTxt;
    end;

    /// <summary>
    /// Retrieves the classified tax category information for PEPPOL BIS, clearing percent for outside scope VAT.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="ClassifiedTaxCategoryID">Returns the tax category identifier.</param>
    /// <param name="ItemSchemeID">Returns the item scheme identifier.</param>
    /// <param name="InvoiceLineTaxPercent">Returns the VAT percentage or empty for outside scope VAT.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Returns the tax category scheme identifier.</param>
    procedure GetLineItemClassfiedTaxCategoryBIS(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        GetLineItemClassfiedTaxCategory(
          SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
        if ClassifiedTaxCategoryID = GetTaxCategoryO() then
            InvoiceLineTaxPercent := '';
    end;

    /// <summary>
    /// Retrieves the additional item property information from item variant.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="AdditionalItemPropertyName">Returns the variant code as property name.</param>
    /// <param name="AdditionalItemPropertyValue">Returns the variant description as property value.</param>
    procedure GetLineAdditionalItemPropertyInfo(SalesLine: Record "Sales Line"; var AdditionalItemPropertyName: Text; var AdditionalItemPropertyValue: Text)
    var
        ItemVariant: Record "Item Variant";
    begin
        AdditionalItemPropertyName := '';
        AdditionalItemPropertyValue := '';

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;
        if SalesLine."No." = '' then
            exit;
        if not ItemVariant.Get(SalesLine."No.", SalesLine."Variant Code") then
            exit;

        AdditionalItemPropertyName := ItemVariant.Code;
        AdditionalItemPropertyValue := ItemVariant.Description;
    end;

    /// <summary>
    /// Retrieves the line price information.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvoiceLinePriceAmount">Returns the unit price excluding VAT.</param>
    /// <param name="InvLinePriceAmountCurrencyID">Returns the currency code.</param>
    /// <param name="BaseQuantity">Returns the base quantity (1).</param>
    /// <param name="UnitCode">Returns the unit of measure code.</param>
    procedure GetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var InvLinePriceAmountCurrencyID: Text; var BaseQuantity: Text; var UnitCode: Text)
    var
        unitCodeListID: Text;
        VATBaseIdx: Decimal;
    begin
        if SalesHeader."Prices Including VAT" then begin
            VATBaseIdx := 1 + SalesLine."VAT %" / 100;
            InvoiceLinePriceAmount := Format(Round(SalesLine."Unit Price" / VATBaseIdx), 0, 9)
        end else
            InvoiceLinePriceAmount := Format(SalesLine."Unit Price", 0, 9);
        InvLinePriceAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        BaseQuantity := '1';
        GetLineUnitCodeInfo(SalesLine, UnitCode, unitCodeListID);

        OnAfterGetLinePriceInfo(
          SalesLine, SalesHeader, InvoiceLinePriceAmount, BaseQuantity, UnitCode);
    end;

    /// <summary>
    /// Retrieves the line price allowance charge information.
    /// </summary>
    /// <param name="PriceChargeIndicator">Returns the charge indicator.</param>
    /// <param name="PriceAllowanceChargeAmount">Returns the allowance charge amount.</param>
    /// <param name="PriceAllowanceAmountCurrencyID">Returns the currency code.</param>
    /// <param name="PriceAllowanceChargeBaseAmount">Returns the base amount for allowance.</param>
    /// <param name="PriceAllowChargeBaseAmtCurrID">Returns the currency code for base amount.</param>
    procedure GetLinePriceAllowanceChargeInfo(var PriceChargeIndicator: Text; var PriceAllowanceChargeAmount: Text; var PriceAllowanceAmountCurrencyID: Text; var PriceAllowanceChargeBaseAmount: Text; var PriceAllowChargeBaseAmtCurrID: Text)
    begin
        PriceChargeIndicator := '';
        PriceAllowanceChargeAmount := '';
        PriceAllowanceAmountCurrencyID := '';
        PriceAllowanceChargeBaseAmount := '';
        PriceAllowChargeBaseAmtCurrID := '';
    end;

    local procedure GetSalesDocCurrencyCode(SalesHeader: Record "Sales Header"): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if SalesHeader."Currency Code" = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            exit(GLSetup."LCY Code");
        end;
        exit(SalesHeader."Currency Code");
    end;

    local procedure GetSalesperson(SalesHeader: Record "Sales Header"; var Salesperson: Record "Salesperson/Purchaser")
    begin
        if SalesHeader."Salesperson Code" = '' then
            Salesperson.Init()
        else
            Salesperson.Get(SalesHeader."Salesperson Code");
    end;

    /// <summary>
    /// Retrieves the billing reference information for a credit memo.
    /// </summary>
    /// <param name="SalesCrMemoHeader">Specifies the sales credit memo header record.</param>
    /// <param name="InvoiceDocRefID">Returns the referenced invoice document number.</param>
    /// <param name="InvoiceDocRefIssueDate">Returns the referenced invoice posting date.</param>
    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if (SalesCrMemoHeader."Applies-to Doc. Type" = SalesCrMemoHeader."Applies-to Doc. Type"::Invoice) and
           SalesInvoiceHeader.Get(SalesCrMemoHeader."Applies-to Doc. No.")
        then begin
            InvoiceDocRefID := SalesInvoiceHeader."No.";
            InvoiceDocRefIssueDate := Format(SalesInvoiceHeader."Posting Date", 0, 9);
        end;
    end;

    local procedure GetCountryISOCode(CountryRegionCode: Code[10]): Code[2]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."ISO Code");
    end;

    /// <summary>
    /// Calculates and accumulates VAT totals from a sales line into the VAT amount line buffer.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record to process.</param>
    /// <param name="VATAmtLine">Returns the accumulated VAT amount line totals.</param>
    procedure GetTotals(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            VATPostingSetup.Init();
        VATAmtLine.Init();
        VATAmtLine."VAT Identifier" := FORMAT(SalesLine."VAT %");
        VATAmtLine."VAT Calculation Type" := SalesLine."VAT Calculation Type";
        VATAmtLine."Tax Group Code" := SalesLine."Tax Group Code";
        VATAmtLine."Tax Category" := VATPostingSetup."Tax Category";
        VATAmtLine."VAT %" := SalesLine."VAT %";
        VATAmtLine."VAT Base" := SalesLine.Amount;
        VATAmtLine."Amount Including VAT" := SalesLine."Amount Including VAT";
        if SalesLine."Allow Invoice Disc." then
            VATAmtLine."Inv. Disc. Base Amount" := SalesLine."Line Amount";
        VATAmtLine."Invoice Discount Amount" := SalesLine."Inv. Discount Amount";
        VATAmtLine."Pmt. Discount Amount" += SalesLine."Pmt. Discount Amount";

        IsHandled := false;
        OnGetTotalsOnBeforeInsertVATAmtLine(SalesLine, VATAmtLine, VATPostingSetup, IsHandled);
        if not IsHandled then
            if VATAmtLine.InsertLine() then begin
                VATAmtLine."Line Amount" += SalesLine."Line Amount";
                VATAmtLine.Modify();
            end;
    end;

    /// <summary>
    /// Retrieves and accumulates tax categories from sales lines into a buffer.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record to process.</param>
    /// <param name="VATProductPostingGroupCategory">Returns the accumulated tax categories.</param>
    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            VATPostingSetup.Init();
        if not VATProductPostingGroup.Get(SalesLine."VAT Prod. Posting Group") then
            VATProductPostingGroup.Init();

        VATProductPostingGroupCategory.Init();
        VATProductPostingGroupCategory.Code := VATPostingSetup."Tax Category";
        VATProductPostingGroupCategory.Description := VATProductPostingGroup.Description;
        if VATProductPostingGroupCategory.Insert() then;
    end;

    /// <summary>
    /// Retrieves the invoice rounding line if it exists.
    /// </summary>
    /// <param name="TempSalesLine">Returns the invoice rounding line if found.</param>
    /// <param name="SalesLine">Specifies the sales line record to check.</param>
    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        if TempSalesLine."Line No." <> 0 then
            exit;

        if IsRoundingLine(SalesLine, SalesLine."Bill-to Customer No.") then begin
            TempSalesLine.TransferFields(SalesLine);
            TempSalesLine.Insert();
        end;
    end;

    /// <summary>
    /// Retrieves the tax exemption reason for specific tax categories.
    /// </summary>
    /// <param name="VATProductPostingGroupCategory">Specifies the VAT product posting group category buffer.</param>
    /// <param name="TaxExemptionReasonTxt">Returns the tax exemption reason description.</param>
    /// <param name="TaxCategoryID">Specifies the tax category identifier to look up.</param>
    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        TaxExemptionReasonTxt := '';
        if not (TaxCategoryID in [GetTaxCategoryE(), GetTaxCategoryG(), GetTaxCategoryK(), GetTaxCategoryO(), GetTaxCategoryAE()]) then
            exit;
        if VATProductPostingGroupCategory.Get(TaxCategoryID) then
            TaxExemptionReasonTxt := VATProductPostingGroupCategory.Description;
    end;

    /// <summary>
    /// Returns the PEPPOL telemetry token for feature usage tracking.
    /// </summary>
    /// <returns>Returns the PEPPOL telemetry token value.</returns>
    procedure GetPeppolTelemetryTok(): Text
    begin
        exit(PeppolTelemetryTok);
    end;

    local procedure GetInvoiceTypeCode(): Text
    begin
        exit('380');
    end;

    local procedure GetUNCL1001ListID(): Text
    begin
        exit('UNCL1001');
    end;

    local procedure GetISO4217ListID(): Text
    begin
        exit('ISO4217');
    end;

    local procedure GetISO3166_1Alpha2(): Text
    begin
        exit('ISO3166-1:Alpha2');
    end;

    local procedure GetUNCL4461ListID(): Text
    begin
        exit('UNCL4461');
    end;

    local procedure GetUNCL4465ListID(): Text
    begin
        exit('UNCL4465');
    end;

    local procedure GetUNECERec20ListID(): Text
    begin
        exit('UNECERec20');
    end;

    /// <summary>
    /// Returns the unit of measure code for piece in UNECE Rec 20 list (EA).
    /// </summary>
    /// <returns>Returns the EA unit code.</returns>
    [Scope('OnPrem')]
    procedure GetUoMforPieceINUNECERec20ListID(): Code[10]
    begin
        exit(UoMforPieceINUNECERec20ListIDTxt);
    end;

    local procedure GetGLNSchemeIDByFormat(IsBISBillling: Boolean): Text
    begin
        if IsBISBillling then
            exit(GetGLNSchemeID());
        exit(GLNTxt);
    end;

    local procedure GetGLNSchemeID(): Text
    begin
        exit('0088');
    end;

    local procedure GetVATSchemeByFormat(CountryRegionCode: Code[10]; IsBISBilling: Boolean): Text
    begin
        if IsBISBilling and not UseVATSchemeID(CountryRegionCode) then
            exit('');
        exit(GetVATScheme(CountryRegionCode));
    end;

    /// <summary>
    /// Retrieves the VAT scheme for a country/region.
    /// </summary>
    /// <param name="CountryRegionCode">Specifies the country/region code.</param>
    /// <returns>Returns the VAT scheme for the specified country/region.</returns>
    procedure GetVATScheme(CountryRegionCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
        CompanyInfo: Record "Company Information";
    begin
        if CountryRegionCode = '' then begin
            CompanyInfo.Get();
            CompanyInfo.TestField("Country/Region Code");
            CountryRegion.Get(CompanyInfo."Country/Region Code");
        end else
            CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."VAT Scheme");
    end;

    /// <summary>
    /// Get the tax category VAT reverse charge
    /// </summary>
    /// <returns>Text: AE</returns>
    local procedure GetTaxCategoryAE(): Text
    begin
        exit('AE');
    end;

    /// <summary>
    /// Get the tax category exempt from tax
    /// </summary>
    /// <returns>Text: E</returns>
    local procedure GetTaxCategoryE(): Text
    begin
        exit('E');
    end;

    local procedure GetTaxCategoryG(): Text
    begin
        exit('G');
    end;

    /// <summary>
    /// Get the tax category VAT exempt for EEA intra-community supply of goods and services
    /// </summary>
    /// <returns>Text: K</returns>
    local procedure GetTaxCategoryK(): Text
    begin
        exit('K');
    end;

    /// <summary>
    /// Get the tax category outside the scope of VAT
    /// </summary>
    /// <returns>Text: O</returns>
    local procedure GetTaxCategoryO(): Text
    begin
        exit('O');
    end;

    /// <summary>
    /// Get the tax category zero rated items
    /// </summary>
    /// <returns>Text: Z</returns>
    local procedure GetTaxCategoryZ(): Text
    begin
        exit('Z');
    end;

    /// <summary>
    /// Get the tax category for standard rated items
    /// </summary>
    /// <returns>Text: S</returns>
    local procedure GetTaxCategoryS(): Text
    begin
        exit('S');
    end;

    /// <summary>
    /// Check if the VAT category is one of the categories with 0% VAT
    /// </summary>
    /// <param name="TaxCategory">Tax category code</param>
    /// <returns>True if category is one of Z, E, AE, K or G</returns>
    procedure IsZeroVatCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory in [
            GetTaxCategoryZ(), // Zero rated goods
            GetTaxCategoryE(), // Exempt from tax
            GetTaxCategoryAE(), // VAT reverse charge
            GetTaxCategoryK(), // VAT exempt for EEA intra-community supply of goods and services
            GetTaxCategoryG(), // Free export item, tax not charged
            GetTaxCategoryO() // Outside the scope of VAT
        ]);
    end;

    /// <summary>
    /// Check if the VAT category is standard rated
    /// </summary>
    /// <param name="TaxCategory">Tax category code</param>
    /// <returns>True if category is S</returns>
    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = GetTaxCategoryS());
    end;

    /// <summary>
    /// Check if the VAT category is outside the scope of VAT
    /// </summary>
    /// <param name="TaxCategory">Tax category code</param>
    /// <returns>True if category is O</returns>
    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(TaxCategory = GetTaxCategoryO());
    end;

    internal procedure FormatVATRegistrationNo(VATRegistrationNo: Text; CountryCode: Code[10]; IsBISBilling: Boolean; IsPartyTaxScheme: Boolean): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if VATRegistrationNo = '' then
            exit;
        if IsBISBilling then begin
            VATRegistrationNo := DelChr(VATRegistrationNo);

            if IsPartyTaxScheme or (UseVATSchemeID(CountryCode)) then
                if CountryRegion.Get(CountryCode) and (CountryRegion."ISO Code" <> '') then
                    if StrPos(VATRegistrationNo, CountryRegion."ISO Code") <> 1 then
                        VATRegistrationNo := CountryRegion."ISO Code" + VATRegistrationNo;
        end;

        exit(VATRegistrationNo);
    end;

    local procedure UseVATSchemeID(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit(false);
        // Use ISO 3166 Country Codes
        exit(CountryRegion."ISO Code" = 'DK');
    end;

    /// <summary>
    /// Initializes the XML export by creating a temporary file for output.
    /// </summary>
    /// <param name="OutFile">Returns the file handle for the output file.</param>
    /// <param name="XmlServerPath">Returns the server path for the XML file.</param>
    [Scope('OnPrem')]
    procedure InitializeXMLExport(var OutFile: File; var XmlServerPath: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        XmlServerPath := FileManagement.ServerTempFileName('xml');

        if StrLen(XmlServerPath) > 250 then
            Error(ExportPathGreaterThan250Err);

        if not Exists(XmlServerPath) then
            OutFile.Create(XmlServerPath)
        else
            OutFile.Open(XmlServerPath);
    end;

    /// <summary>
    /// Checks if a sales line is an invoice rounding line.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to check.</param>
    /// <param name="CustomerNo">Specifies the customer number to determine the posting group.</param>
    /// <returns>Returns true if the line is an invoice rounding line, false otherwise.</returns>
    procedure IsRoundingLine(SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Boolean;
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if SalesLine.Type = SalesLine.Type::"G/L Account" then begin
            Customer.Get(CustomerNo);
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if SalesLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;



    /// <summary>
    /// Transfers fields from a posted document header to a sales header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record (typically posted invoice or credit memo header).</param>
    /// <param name="ToSalesHeader">Returns the sales header with transferred fields.</param>
    procedure TransferHeaderToSalesHeader(FromRecord: Variant; var ToSalesHeader: Record "Sales Header")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesHeader;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferHeaderToSalesHeader(FromRecord, ToRecord);

        ToSalesHeader := ToRecord;
    end;

    /// <summary>
    /// Transfers fields from a posted document line to a sales line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record (typically posted invoice or credit memo line).</param>
    /// <param name="ToSalesLine">Returns the sales line with transferred fields.</param>
    procedure TransferLineToSalesLine(FromRecord: Variant; var ToSalesLine: Record "Sales Line")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesLine;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferLineToSalesLine(FromRecord, ToRecord);

        ToSalesLine := ToRecord;
    end;

    /// <summary>
    /// Transfers fields from a source record to a sales invoice header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record to transfer fields from.</param>
    /// <param name="ToSalesInvoiceHeader">Returns the sales invoice header with transferred fields.</param>
    procedure TransferHeaderToSalesInvoiceHeader(FromRecord: Variant; var ToSalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesInvoiceHeader;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferHeaderToSalesInvoiceHeader(FromRecord, ToRecord);

        ToSalesInvoiceHeader := ToRecord;
    end;

    /// <summary>
    /// Transfers fields from a source record to a sales credit memo header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record to transfer fields from.</param>
    /// <param name="ToSalesCrMemoHeader">Returns the sales credit memo header with transferred fields.</param>
    procedure TransferHeaderToSalesCrMemoHeader(FromRecord: Variant; var ToSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesCrMemoHeader;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferHeaderToSalesCrMemoHeader(FromRecord, ToRecord);

        ToSalesCrMemoHeader := ToRecord;
    end;

    /// <summary>
    /// Transfers fields from a source record to a sales invoice line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record to transfer fields from.</param>
    /// <param name="ToSalesInvoiceLine">Returns the sales invoice line with transferred fields.</param>
    procedure TransferLineToSalesInvoiceLine(FromRecord: Variant; var ToSalesInvoiceLine: Record "Sales Invoice Line")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesInvoiceLine;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferLineToSalesInvoiceLine(FromRecord, ToRecord);

        ToSalesInvoiceLine := ToRecord;
    end;

    /// <summary>
    /// Transfers fields from a source record to a sales credit memo line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record to transfer fields from.</param>
    /// <param name="ToSalesCrMemoLine">Returns the sales credit memo line with transferred fields.</param>
    procedure TransferLineToSalesCrMemoLine(FromRecord: Variant; var ToSalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesCrMemoLine;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferLineToSalesCrMemoLine(FromRecord, ToRecord);

        ToSalesCrMemoLine := ToRecord;
    end;
    /// <summary>
    /// Transfers matching fields between two records using RecordRef.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Returns the target record with transferred fields.</param>
    procedure RecRefTransferFields(FromRecord: Variant; var ToRecord: Variant)
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        i: Integer;
    begin
        FromRecRef.GetTable(FromRecord);
        ToRecRef.GetTable(ToRecord);
        for i := 1 to FromRecRef.FieldCount do begin
            FromFieldRef := FromRecRef.FieldIndex(i);
            if ToRecRef.FieldExist(FromFieldRef.Number) then begin
                ToFieldRef := ToRecRef.Field(FromFieldRef.Number);
                CopyField(FromFieldRef, ToFieldRef);
            end;
        end;
        ToRecRef.SetTable(ToRecord);
    end;

    local procedure CopyField(FromFieldRef: FieldRef; var ToFieldRef: FieldRef)
    begin
        if FromFieldRef.Class <> ToFieldRef.Class then
            exit;

        if FromFieldRef.Type <> ToFieldRef.Type then
            exit;

        if FromFieldRef.Length > ToFieldRef.Length then
            exit;

        ToFieldRef.Value := FromFieldRef.Value();
    end;


    /// <summary>
    /// Finds the next sales invoice record and transfers its fields to a sales header.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the sales invoice header to iterate.</param>
    /// <param name="SalesHeader">Returns the sales header with transferred fields.</param>
    /// <param name="Position">Specifies the position (1 for first, other for next).</param>
    /// <returns>Returns true if a record was found, false otherwise.</returns>
    procedure FindNextSalesInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := SalesInvoiceHeader.Find('-')
        else
            Found := SalesInvoiceHeader.Next() <> 0;
        if Found then
            SalesHeader.TransferFields(SalesInvoiceHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;

        OnAfterFindNextSalesInvoiceRec(SalesInvoiceHeader, SalesHeader, Position, Found);
    end;


    /// <summary>
    /// Finds the next sales invoice line record and transfers its fields to a sales line.
    /// </summary>
    /// <param name="SalesInvoiceLine">Specifies the sales invoice line to iterate.</param>
    /// <param name="SalesLine">Returns the sales line with transferred fields.</param>
    /// <param name="Position">Specifies the position (1 for first, other for next).</param>
    /// <returns>Returns true if a record was found, false otherwise.</returns>
    procedure FindNextSalesInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    var
        Found: Boolean;
    begin
        if Position = 1 then
            Found := SalesInvoiceLine.Find('-')
        else
            Found := SalesInvoiceLine.Next() <> 0;
        if Found then
            SalesLine.TransferFields(SalesInvoiceLine);

        OnAfterFindNextSalesInvoiceLineRec(SalesInvoiceLine, SalesLine, Found);
        exit(Found);
    end;


    /// <summary>
    /// Finds the next sales credit memo record and transfers its fields to a sales header.
    /// </summary>
    /// <param name="SalesCrMemoHeader">Specifies the sales credit memo header to iterate.</param>
    /// <param name="SalesHeader">Returns the sales header with transferred fields.</param>
    /// <param name="Position">Specifies the position (1 for first, other for next).</param>
    /// <returns>Returns true if a record was found, false otherwise.</returns>
    procedure FindNextSalesCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := SalesCrMemoHeader.Find('-')
        else
            Found := SalesCrMemoHeader.Next() <> 0;
        if Found then
            SalesHeader.TransferFields(SalesCrMemoHeader);

        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";

        OnAfterFindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position, Found);
    end;


    /// <summary>
    /// Finds the next sales credit memo line record and transfers its fields to a sales line.
    /// </summary>
    /// <param name="SalesCrMemoLine">Specifies the sales credit memo line to iterate.</param>
    /// <param name="SalesLine">Returns the sales line with transferred fields.</param>
    /// <param name="Position">Specifies the position (1 for first, other for next).</param>
    /// <returns>Returns true if a record was found, false otherwise.</returns>
    procedure FindNextSalesCreditMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := SalesCrMemoLine.Find('-')
        else
            Found := SalesCrMemoLine.Next() <> 0;
        if Found then
            SalesLine.TransferFields(SalesCrMemoLine);

        OnAfterFindNextSalesCrMemoLineRec(SalesCrMemoLine, SalesLine, Position, Found);
    end;


    /// <summary>
    /// Raised after finding the next sales invoice line record during PEPPOL export iteration.
    /// </summary>
    /// <param name="SalesInvoiceLine">Specifies the sales invoice line record found.</param>
    /// <param name="SalesLine">Specifies the sales line record with transferred fields.</param>
    /// <param name="Found">Indicates whether a record was found.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;


    /// <summary>
    /// Raised after finding the next sales invoice header record during PEPPOL export iteration.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Specifies the sales invoice header record found.</param>
    /// <param name="SalesHeader">Specifies the sales header record with transferred fields.</param>
    /// <param name="Position">Specifies the position in the iteration (1 for first).</param>
    /// <param name="Found">Indicates whether a record was found.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;


    /// <summary>
    /// Raised after finding the next sales credit memo header record during PEPPOL export iteration.
    /// </summary>
    /// <param name="SalesCrMemoHeader">Specifies the sales credit memo header record found.</param>
    /// <param name="SalesHeader">Specifies the sales header record with transferred fields.</param>
    /// <param name="Position">Specifies the position in the iteration (1 for first).</param>
    /// <param name="Found">Indicates whether a record was found.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;


    /// <summary>
    /// Raised after finding the next sales credit memo line record during PEPPOL export iteration.
    /// </summary>
    /// <param name="SalesCrMemoLine">Specifies the sales credit memo line record found.</param>
    /// <param name="SalesLine">Specifies the sales line record with transferred fields.</param>
    /// <param name="Position">Specifies the position in the iteration (1 for first).</param>
    /// <param name="Found">Indicates whether a record was found.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesCrMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer; var Found: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting customer party information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="CustomerEndpointID">Specifies the customer endpoint identifier.</param>
    /// <param name="CustomerSchemeID">Specifies the scheme identifier for the endpoint.</param>
    /// <param name="CustomerPartyIdentificationID">Specifies the customer party identification.</param>
    /// <param name="CustomerPartyIDSchemeID">Specifies the party identification scheme.</param>
    /// <param name="CustomerName">Specifies the customer name.</param>
    /// <param name="IsBISBilling">Indicates whether this is BIS billing format.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyInfoByFormat(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text; IsBISBilling: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting customer party legal entity information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="CustPartyLegalEntityRegName">Specifies the customer registered name.</param>
    /// <param name="CustPartyLegalEntityCompanyID">Specifies the customer company identifier.</param>
    /// <param name="CustPartyLegalEntityIDSchemeID">Specifies the company ID scheme identifier.</param>
    /// <param name="IsBISBilling">Indicates whether this is BIS billing format.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyLegalEntityByFormat(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text; IsBISBilling: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting supplier party contact information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ContactID">Specifies the contact identifier.</param>
    /// <param name="ContactName">Specifies the contact name.</param>
    /// <param name="Telephone">Specifies the telephone number.</param>
    /// <param name="Telefax">Specifies the telefax number.</param>
    /// <param name="ElectronicMail">Specifies the email address.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting customer party contact information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="Customer">Specifies the customer record.</param>
    /// <param name="CustContactID">Specifies the customer contact identifier.</param>
    /// <param name="CustContactName">Specifies the customer contact name.</param>
    /// <param name="CustContactTelephone">Specifies the customer telephone number.</param>
    /// <param name="CustContactTelefax">Specifies the customer telefax number.</param>
    /// <param name="CustContactElectronicMail">Specifies the customer email address.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; Customer: Record Customer; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving additional document reference information for PEPPOL export.
    /// </summary>
    /// <param name="AdditionalDocumentReferenceID">Specifies the document reference identifier.</param>
    /// <param name="AdditionalDocRefDocumentType">Specifies the document type description.</param>
    /// <param name="URI">Specifies the document URI.</param>
    /// <param name="MimeCode">Specifies the MIME type code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Specifies the Base64 encoded content.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ProcessedDocType">Specifies the document type being processed.</param>
    /// <param name="DocumentAttachments">Specifies the document attachments record.</param>
    /// <param name="FileName">Specifies the attachment filename.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAdditionalDocRefInfo(var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; var DocumentAttachments: Record "Document Attachment"; var FileName: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving general invoice information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ID">Specifies the document number.</param>
    /// <param name="IssueDate">Specifies the document date.</param>
    /// <param name="InvoiceTypeCode">Specifies the invoice type code.</param>
    /// <param name="Note">Specifies the document note.</param>
    /// <param name="TaxPointDate">Specifies the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Specifies the document currency code.</param>
    /// <param name="AccountingCost">Specifies the accounting cost reference.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving general invoice information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ID">Specifies the document number.</param>
    /// <param name="IssueDate">Specifies the document date.</param>
    /// <param name="InvoiceTypeCode">Specifies the invoice type code.</param>
    /// <param name="Note">Specifies the document note.</param>
    /// <param name="TaxPointDate">Specifies the tax point date.</param>
    /// <param name="DocumentCurrencyCode">Specifies the document currency code.</param>
    /// <param name="AccountingCost">Specifies the accounting cost reference.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGeneralInfoProcedure(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving GLN delivery information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ActualDeliveryDate">Specifies the shipment date.</param>
    /// <param name="DeliveryID">Specifies the delivery GLN.</param>
    /// <param name="DeliveryIDSchemeID">Specifies the GLN scheme identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving delivery party name for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="DeliveryPartyNameValue">Specifies the delivery party name.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyNameValue: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving legal monetary information including invoice rounding for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TempSalesLine">Specifies the temporary sales line for invoice rounding.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line record.</param>
    /// <param name="LineExtensionAmount">Specifies the total line extension amount.</param>
    /// <param name="TaxExclusiveAmount">Specifies the amount excluding VAT.</param>
    /// <param name="TaxInclusiveAmount">Specifies the amount including VAT.</param>
    /// <param name="AllowanceTotalAmount">Specifies the total allowance amount.</param>
    /// <param name="ChargeTotalAmount">Specifies the total charge amount.</param>
    /// <param name="PrepaidAmount">Specifies the prepaid amount.</param>
    /// <param name="PayableRoundingAmount">Specifies the rounding amount.</param>
    /// <param name="PayableAmount">Specifies the total payable amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLegalMonetaryInfoWithInvRounding(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var TaxExclusiveAmount: Text; var TaxInclusiveAmount: Text; var AllowanceTotalAmount: Text; var ChargeTotalAmount: Text; var PrepaidAmount: Text; var PayableRoundingAmount: Text; var PayableAmount: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving general line information for PEPPOL export.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvoiceLineID">Specifies the line number.</param>
    /// <param name="InvoiceLineNote">Specifies the line type as note.</param>
    /// <param name="InvoicedQuantity">Specifies the quantity.</param>
    /// <param name="InvoiceLineExtensionAmount">Specifies the line amount.</param>
    /// <param name="InvoiceLineAccountingCost">Specifies the accounting cost reference.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var InvoiceLineAccountingCost: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving line price information for PEPPOL export.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="InvoiceLinePriceAmount">Specifies the unit price excluding VAT.</param>
    /// <param name="BaseQuantity">Specifies the base quantity.</param>
    /// <param name="UnitCode">Specifies the unit of measure code.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var BaseQuantity: Text; var UnitCode: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving order reference information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="OrderReferenceID">Specifies the order reference identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving payment means information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="PaymentMeansCode">Specifies the payment means code.</param>
    /// <param name="PaymentMeansListID">Specifies the payment means list identifier.</param>
    /// <param name="PaymentDueDate">Specifies the payment due date.</param>
    /// <param name="PaymentChannelCode">Specifies the payment channel code.</param>
    /// <param name="PaymentID">Specifies the payment identifier.</param>
    /// <param name="PrimaryAccountNumberID">Specifies the primary account number.</param>
    /// <param name="NetworkID">Specifies the network identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving payee financial account information for PEPPOL export.
    /// </summary>
    /// <param name="CompanyInfo">Specifies the company information record.</param>
    /// <param name="PayeeFinancialAccountID">Specifies the payee bank account number or IBAN.</param>
    /// <param name="FinancialInstitutionBranchID">Specifies the bank branch number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansPayeeFinancialAcc(CompanyInfo: Record "Company Information"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving payee financial account information for PEPPOL BIS export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="PayeeFinancialAccountID">Specifies the payee bank account number or IBAN.</param>
    /// <param name="FinancialInstitutionBranchID">Specifies the bank branch number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving tax total information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line record.</param>
    /// <param name="TaxAmount">Specifies the total VAT amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving tax total information in local currency for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TaxAmount">Specifies the total VAT amount in local currency.</param>
    /// <param name="TaxCurrencyID">Specifies the tax currency identifier.</param>
    /// <param name="TaxTotalCurrencyID">Specifies the tax total currency identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving tax subtotal information for PEPPOL export.
    /// </summary>
    /// <param name="VATAmtLine">Specifies the VAT amount line record.</param>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="TaxableAmount">Specifies the VAT base amount.</param>
    /// <param name="SubtotalTaxAmount">Specifies the VAT amount.</param>
    /// <param name="TransactionCurrencyTaxAmount">Specifies the tax amount in local currency.</param>
    /// <param name="TaxTotalTaxCategoryID">Specifies the tax category identifier.</param>
    /// <param name="schemeID">Specifies the tax scheme identifier.</param>
    /// <param name="TaxCategoryPercent">Specifies the VAT percentage.</param>
    /// <param name="TaxTotalTaxSchemeID">Specifies the tax scheme identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var SubtotalTaxAmount: Text; var TransactionCurrencyTaxAmount: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    begin
    end;

    /// <summary>
    /// Raised before inserting a VAT amount line when calculating totals.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record being processed.</param>
    /// <param name="VATAmtLine">Specifies the VAT amount line being inserted.</param>
    /// <param name="VATPostingSetup">Specifies the VAT posting setup record.</param>
    /// <param name="IsHandled">Set to true to skip the default insert logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetTotalsOnBeforeInsertVATAmtLine(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving line item information for PEPPOL export.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line record.</param>
    /// <param name="Description">Specifies the item description 2.</param>
    /// <param name="Name">Specifies the item description.</param>
    /// <param name="SellersItemIdentificationID">Specifies the item number.</param>
    /// <param name="StandardItemIdentificationID">Specifies the item GTIN.</param>
    /// <param name="StdItemIdIDSchemeID">Specifies the GTIN scheme identifier.</param>
    /// <param name="OriginCountryIdCode">Specifies the country of origin code.</param>
    /// <param name="OriginCountryIdCodeListID">Specifies the country code list identifier.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving contract document reference information for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="ContractDocumentReferenceID">Specifies the contract reference identifier.</param>
    /// <param name="DocumentTypeCode">Specifies the document type code.</param>
    /// <param name="ContractRefDocTypeCodeListID">Specifies the document type code list identifier.</param>
    /// <param name="DocumentType">Specifies the document type description.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting supplier party legal entity information for PEPPOL export.
    /// </summary>
    /// <param name="PartyLegalEntityRegName">Specifies the registered company name.</param>
    /// <param name="PartyLegalEntityCompanyID">Specifies the company identifier.</param>
    /// <param name="PartyLegalEntitySchemeID">Specifies the scheme identifier.</param>
    /// <param name="SupplierRegAddrCityName">Specifies the registered address city.</param>
    /// <param name="SupplierRegAddrCountryIdCode">Specifies the country ISO code.</param>
    /// <param name="SupplRegAddrCountryIdListId">Specifies the country code list identifier.</param>
    /// <param name="IsBISBilling">Indicates whether this is BIS billing format.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyLegalEntityByFormat(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text; IsBISBilling: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document header to a sales header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferHeaderToSalesHeader(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document line to a sales line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferLineToSalesLine(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting supplier party information for PEPPOL export.
    /// </summary>
    /// <param name="SupplierEndpointID">Specifies the supplier endpoint identifier.</param>
    /// <param name="SupplierSchemeID">Specifies the scheme identifier for the endpoint.</param>
    /// <param name="SupplierName">Specifies the company name.</param>
    /// <param name="IsBISBilling">Indicates whether this is BIS billing format.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyInfoByFormat(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text; IsBISBilling: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving accounting supplier party identification ID for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="PartyIdentificationID">Specifies the party identification ID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
    end;

    /// <summary>
    /// Raised after retrieving buyer reference for PEPPOL export.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="BuyerReference">Specifies the buyer reference value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBuyerReference(SalesHeader: Record "Sales Header"; var BuyerReference: Text)
    begin
    end;

    /// <summary>
    /// Raised before generating a PDF attachment as an additional document reference.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Specifies the document reference identifier.</param>
    /// <param name="AdditionalDocRefDocumentType">Specifies the document type description.</param>
    /// <param name="URI">Specifies the document URI.</param>
    /// <param name="MimeCode">Specifies the MIME type code.</param>
    /// <param name="Filename">Specifies the attachment filename.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Specifies the Base64 encoded content.</param>
    /// <param name="IsHandled">Set to true to skip the default PDF generation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var Filename: Text; var EmbeddedDocumentBinaryObject: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document header to a sales invoice header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales invoice header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferHeaderToSalesInvoiceHeader(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document header to a sales credit memo header record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales credit memo header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferHeaderToSalesCrMemoHeader(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document line to a sales invoice line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales invoice line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferLineToSalesInvoiceLine(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    /// <summary>
    /// Raised after transferring fields from a posted document line to a sales credit memo line record.
    /// </summary>
    /// <param name="FromRecord">Specifies the source record.</param>
    /// <param name="ToRecord">Specifies the target sales credit memo line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferLineToSalesCrMemoLine(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;
}
