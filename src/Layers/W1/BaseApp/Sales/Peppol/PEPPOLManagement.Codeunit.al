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
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Text;
using System.Utilities;
using System.IO;
using System.Telemetry;

codeunit 1605 "PEPPOL Management"
{

    trigger OnRun()
    begin
    end;

    var
        ProcessedDocType: Enum "PEPPOL Processing Type";
        SalespersonTxt: Label 'Salesperson';
        InvoiceDisAmtTxt: Label 'Invoice Discount Amount';
        LineDisAmtTxt: Label 'Line Discount Amount';
        GLNTxt: Label 'GLN', Locked = true;
        VATTxt: Label 'VAT', Locked = true;
        MultiplyTxt: Label 'Multiply', Locked = true;
        IBANPaymentSchemeIDTxt: Label 'IBAN', Locked = true;
        LocalPaymentSchemeIDTxt: Label 'LOCAL', Locked = true;
        BICTxt: Label 'BIC', Locked = true;
        AllowanceChargeReasonCodeTxt: Label '104', Locked = true;
        PaymentMeansFundsTransferCodeTxt: Label '31', Locked = true;
        GTINTxt: Label '0160', Locked = true;
        UoMforPieceINUNECERec20ListIDTxt: Label 'EA', Locked = true;
#pragma warning disable AA0470
        NoUnitOfMeasureErr: Label 'The %1 %2 contains lines on which the %3 field is empty.', Comment = '1: document type, 2: document no 3 Unit of Measure Code';
#pragma warning restore AA0470
        ExportPathGreaterThan250Err: Label 'The export path is longer than 250 characters.';
        PeppolTelemetryTok: Label 'PEPPOL', Locked = true;

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

    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        StartDate := '';
        EndDate := '';
    end;

    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        OrderReferenceID := SalesHeader."External Document No.";

        OnAfterGetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        OrderReferenceID := SalesHeader."External Document No.";
        if OrderReferenceID = '' then
            OrderReferenceID := SalesHeader."No.";
    end;

    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        ContractDocumentReferenceID := SalesHeader."No.";
        DocumentTypeCode := '';
        ContractRefDocTypeCodeListID := GetUNCL1001ListID();
        DocumentType := '';

        OnAfterGetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

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

    procedure GetAccountingSupplierPartyInfo(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text)
    begin
        GetAccountingSupplierPartyInfoByFormat(SupplierEndpointID, SupplierSchemeID, SupplierName, false);
    end;

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

    procedure GetAccountingSupplierPartyTaxScheme(var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyID := FormatVATRegistrationNo(CompanyInfo.GetVATRegistrationNumber(), CompanyInfo."Country/Region Code", true, true);
        CompanyIDSchemeID := GetVATScheme(CompanyInfo."Country/Region Code");
        TaxSchemeID := VATTxt;
    end;

    procedure GetAccountingSupplierPartyTaxSchemeBIS(var VATAmtLine: Record "VAT Amount Line"; var CompanyID: Text; var CompanyIDSchemeID: Text; var TaxSchemeID: Text)
    begin
        VATAmtLine.SetFilter("Tax Category", '<>%1', GetTaxCategoryO());
        if not VATAmtLine.IsEmpty() then
            GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        VATAmtLine.SetRange("Tax Category");
        CompanyID := DelChr(CompanyID);
        CompanyIDSchemeID := '';
    end;

    procedure GetAccountingSupplierPartyLegalEntity(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text)
    begin
        GetAccountingSupplierPartyLegalEntityByFormat(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID,
          SupplierRegAddrCityName, SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId, false);
    end;

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

    procedure GetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
        PartyIdentificationID := '';
        OnAfterGetAccountingSupplierPartyIdentificationID(SalesHeader, PartyIdentificationID);
    end;

    procedure GetAccountingCustomerPartyInfo(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text)
    begin
        GetAccountingCustomerPartyInfoByFormat(
          SalesHeader, CustomerEndpointID, CustomerSchemeID,
          CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerName, false);
    end;

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

    procedure GetAccountingCustomerPartyTaxScheme(SalesHeader: Record "Sales Header"; var CustPartyTaxSchemeCompanyID: Text; var CustPartyTaxSchemeCompIDSchID: Text; var CustTaxSchemeID: Text)
    begin
        GetAccountingCustomerPartyTaxSchemeByFormat(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID, false);
    end;

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

    procedure GetAccountingCustomerPartyLegalEntity(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text)
    begin
        GetAccountingCustomerPartyLegalEntityByFormat(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID, false);
    end;

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

    procedure GetTaxRepresentativePartyInfo(var TaxRepPartyNameName: Text; var PayeePartyTaxSchemeCompanyID: Text; var PayeePartyTaxSchCompIDSchemeID: Text; var PayeePartyTaxSchemeTaxSchemeID: Text)
    begin
        TaxRepPartyNameName := '';
        PayeePartyTaxSchemeCompanyID := '';
        PayeePartyTaxSchCompIDSchemeID := '';
        PayeePartyTaxSchemeTaxSchemeID := '';
    end;

    procedure GetDeliveryInfo(var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
        ActualDeliveryDate := '';
        DeliveryID := '';
        DeliveryIDSchemeID := '';
    end;

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

#if not CLEAN25
    [Obsolete('Replaced by GetPaymentMeansPayeeFinancialAccBIS with SalesHeader parameter.', '25.0')]
    procedure GetPaymentMeansPayeeFinancialAccBIS(var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    var
        CompanyInfo: Record "Company Information";
        SalesHeader: Record "Sales Header";
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
#endif

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

    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        GetAllowanceChargeInfo(
          VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason,
          Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
        if TaxCategoryID = GetTaxCategoryO() then
            Percent := '';
    end;

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

    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
        VATAmtLine.CalcSums(VATAmtLine."VAT Amount");
        TaxAmount := Format(VATAmtLine."VAT Amount", 0, 9);
        TaxTotalCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        OnAfterGetTaxTotalInfo(SalesHeader, VATAmtLine, TaxAmount);
    end;

    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        TaxableAmount := Format(VATAmtLine."VAT Base", 0, 9);
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

            PayableAmount := Format(Round(VATAmtLine."Amount Including VAT", 0.01), 0, 9);
            PayableAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        end else begin
            PayableRoundingAmount := Format(TempSalesLine."Amount Including VAT", 0, 9);
            PayableRndingAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

            PayableAmount := Format(Round(VATAmtLine."Amount Including VAT" + TempSalesLine."Amount Including VAT", 0.01), 0, 9);
            PayableAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        end;

        OnAfterGetLegalMonetaryInfoWithInvRounding(
          SalesHeader, TempSalesLine, VATAmtLine, LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount,
          AllowanceTotalAmount, ChargeTotalAmount, PrepaidAmount, PayableRoundingAmount, PayableAmount);
    end;


    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)
    begin
        LineExtensionAmount := Format(Round(VATAmtLine."VAT Base", 0.01) + Round(VATAmtLine."Invoice Discount Amount", 0.01), 0, 9);
        LegalMonetaryTotalCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        TaxExclusiveAmount := Format(Round(VATAmtLine."VAT Base", 0.01), 0, 9);
        TaxExclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        TaxInclusiveAmount := Format(Round(VATAmtLine."Amount Including VAT", 0.01, '>'), 0, 9); // Should be two decimal places
        TaxInclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        AllowanceTotalAmount := Format(Round(VATAmtLine."Invoice Discount Amount", 0.01), 0, 9);
        AllowanceTotalAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        TaxInclusiveAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);

        ChargeTotalAmount := '';
        ChargeTotalAmountCurrencyID := '';
    end;

    procedure GetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)
    begin
        InvoiceLineID := Format(SalesLine."Line No.", 0, 9);
        InvoiceLineNote := DelChr(Format(SalesLine.Type), '<>');
        InvoicedQuantity := Format(SalesLine.Quantity, 0, 9);
        InvoiceLineExtensionAmount := Format(SalesLine."VAT Base Amount" + SalesLine."Inv. Discount Amount", 0, 9);
        LineExtensionAmountCurrencyID := GetSalesDocCurrencyCode(SalesHeader);
        InvoiceLineAccountingCost := '';

        OnAfterGetLineGeneralInfo(
          SalesLine, SalesHeader, InvoiceLineID, InvoiceLineNote, InvoicedQuantity,
          InvoiceLineExtensionAmount, InvoiceLineAccountingCost);
    end;

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

    procedure GetLineInvoicePeriodInfo(var InvLineInvoicePeriodStartDate: Text; var InvLineInvoicePeriodEndDate: Text)
    begin
        InvLineInvoicePeriodStartDate := '';
        InvLineInvoicePeriodEndDate := '';
    end;

    procedure GetLineOrderLineRefInfo()
    begin
    end;

    procedure GetLineDeliveryInfo(var InvoiceLineActualDeliveryDate: Text; var InvoiceLineDeliveryID: Text; var InvoiceLineDeliveryIDSchemeID: Text)
    begin
        InvoiceLineActualDeliveryDate := '';
        InvoiceLineDeliveryID := '';
        InvoiceLineDeliveryIDSchemeID := '';
    end;

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

    procedure GetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyName: Text)
    begin
        DeliveryPartyName := '';
        OnAfterGetDeliveryPartyName(SalesHeader, DeliveryPartyName);
    end;

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

    procedure GetLineTaxTotal(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineTaxAmount: Text; var currencyID: Text)
    begin
        InvoiceLineTaxAmount := Format(SalesLine."Amount Including VAT" - SalesLine.Amount, 0, 9);
        currencyID := GetSalesDocCurrencyCode(SalesHeader);
    end;

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

    procedure GetLineItemCommodityClassficationInfo(var CommodityCode: Text; var CommodityCodeListID: Text; var ItemClassificationCode: Text; var ItemClassificationCodeListID: Text)
    begin
        CommodityCode := '';
        CommodityCodeListID := '';

        ItemClassificationCode := '';
        ItemClassificationCodeListID := '';
    end;

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

    procedure GetLineItemClassfiedTaxCategoryBIS(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)
    begin
        GetLineItemClassfiedTaxCategory(
          SalesLine, ClassifiedTaxCategoryID, ItemSchemeID, InvoiceLineTaxPercent, ClassifiedTaxCategorySchemeID);
        if ClassifiedTaxCategoryID = GetTaxCategoryO() then
            InvoiceLineTaxPercent := '';
    end;

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

        IsHandled := false;
        OnGetTotalsOnBeforeInsertVATAmtLine(SalesLine, VATAmtLine, VATPostingSetup, IsHandled);
        if not IsHandled then
            if VATAmtLine.InsertLine() then begin
                VATAmtLine."Line Amount" += SalesLine."Line Amount";
                VATAmtLine.Modify();
            end;
    end;

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

    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        if TempSalesLine."Line No." <> 0 then
            exit;

        if IsRoundingLine(SalesLine, SalesLine."Bill-to Customer No.") then begin
            TempSalesLine.TransferFields(SalesLine);
            TempSalesLine.Insert();
        end;
    end;

    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        TaxExemptionReasonTxt := '';
        if not (TaxCategoryID in [GetTaxCategoryE(), GetTaxCategoryG(), GetTaxCategoryK(), GetTaxCategoryO(), GetTaxCategoryAE()]) then
            exit;
        if VATProductPostingGroupCategory.Get(TaxCategoryID) then
            TaxExemptionReasonTxt := VATProductPostingGroupCategory.Description;
    end;

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

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit ServPEPPOLManagement', '25.0')]
    procedure MapServiceLineTypeToSalesLineType(ServiceLineType: Enum Microsoft.Service.Document."Service Line Type"): Integer
    var
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
    begin
        exit(ServPEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceLineType).AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit ServPEPPOLManagement', '25.0')]
    procedure MapServiceLineTypeToSalesLineTypeEnum(ServiceLineType: Enum Microsoft.Service.Document."Service Line Type"): Enum "Sales Line Type"
    var
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
    begin
        exit(ServPEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceLineType));
    end;
#endif

    procedure TransferHeaderToSalesHeader(FromRecord: Variant; var ToSalesHeader: Record "Sales Header")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesHeader;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferHeaderToSalesHeader(FromRecord, ToRecord);

        ToSalesHeader := ToRecord;
    end;

    procedure TransferLineToSalesLine(FromRecord: Variant; var ToSalesLine: Record "Sales Line")
    var
        ToRecord: Variant;
    begin
        ToRecord := ToSalesLine;
        RecRefTransferFields(FromRecord, ToRecord);

        OnAfterRecRefTransferFieldsOnTransferLineToSalesLine(FromRecord, ToRecord);

        ToSalesLine := ToRecord;
    end;

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

#if not CLEAN25
    [Obsolete('Service documents separated to codeunit ServPEPPOLManagement', '25.0')]
    procedure FindNextInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header"; var SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; Position: Integer) Found: Boolean
    var
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                Found := FindNextSalesInvoiceRec(SalesInvoiceHeader, SalesHeader, Position);
            ProcessedDocType::Service:
                Found := ServPEPPOLManagement.FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position);
        end;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;

        OnAfterFindNextInvoiceRec(SalesInvoiceHeader, ServiceInvoiceHeader, SalesHeader, ProcessedDocType, Position, Found);
    end;
#endif

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

#if not CLEAN25
    [Obsolete('Service documents separated to codeunit ServPEPPOLManagement', '25.0')]
    procedure FindNextInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; ProcessedDocType: Option Sale,Service; Position: Integer) Found: Boolean
    var
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(FindNextSalesInvoiceLineRec(SalesInvoiceLine, SalesLine, Position));
            ProcessedDocType::Service:
                exit(ServPEPPOLManagement.FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position));
        end;

        OnAfterFindNextInvoiceLineRec(SalesInvoiceLine, ServiceInvoiceLine, SalesLine, ProcessedDocType, Found);
    end;
#endif

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

#if not CLEAN25
    [Obsolete('Service documents separated to codeunit ServPEPPOLManagement', '25.0')]
    procedure FindNextCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ServiceCrMemoHeader: Record Microsoft.Service.History."Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; Position: Integer) Found: Boolean
    var
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                exit(FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
            ProcessedDocType::Service:
                exit(ServPEPPOLManagement.FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position));
        end;
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";

        OnAfterFindNextCreditMemoRec(SalesCrMemoHeader, ServiceCrMemoHeader, SalesHeader, ProcessedDocType, Position, Found);
    end;
#endif

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

#if not CLEAN25
    [Obsolete('Service documents separated to codeunit ServPEPPOLManagement', '25.0')]
    procedure FindNextCreditMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; ProcessedDocType: Option Sale,Service; Position: Integer) Found: Boolean
    begin
        case ProcessedDocType of
            ProcessedDocType::Sale:
                begin
                    if Position = 1 then
                        Found := SalesCrMemoLine.Find('-')
                    else
                        Found := SalesCrMemoLine.Next() <> 0;
                    if Found then
                        SalesLine.TransferFields(SalesCrMemoLine);
                end;
            ProcessedDocType::Service:
                begin
                    if Position = 1 then
                        Found := ServiceCrMemoLine.Find('-')
                    else
                        Found := ServiceCrMemoLine.Next() <> 0;
                    if Found then begin
                        TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                        SalesLine.Type := MapServiceLineTypeToSalesLineTypeEnum(ServiceCrMemoLine.Type);
                    end;
                end;
        end;

        OnAfterFindNextCreditMemoLineRec(SalesCrMemoLine, ServiceCrMemoLine, SalesLine, ProcessedDocType, Position, Found);
    end;
#endif

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

#if not CLEAN25
    [Obsolete('Replaced by event OnAfterFindNextSalesInvoiceLineRec', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; ProcessedDocType: Option Sale,Service; var Found: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnAfterFindNextSalesInvoiceRec', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var ServiceInvoiceHeader: Record Microsoft.Service.History."Service Invoice Header"; var SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; Position: Integer; var Found: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnAfterFindNextSalesCreditMemoRec', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ServiceCrMemoHeader: Record Microsoft.Service.History."Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; Position: Integer; var Found: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnAfterFindNextSalesCreditMemoLineRec', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextCreditMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; ProcessedDocType: Option Sale,Service; Position: Integer; var Found: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextSalesCrMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyInfoByFormat(SalesHeader: Record "Sales Header"; var CustomerEndpointID: Text; var CustomerSchemeID: Text; var CustomerPartyIdentificationID: Text; var CustomerPartyIDSchemeID: Text; var CustomerName: Text; IsBISBilling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyLegalEntityByFormat(SalesHeader: Record "Sales Header"; var CustPartyLegalEntityRegName: Text; var CustPartyLegalEntityCompanyID: Text; var CustPartyLegalEntityIDSchemeID: Text; IsBISBilling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingCustomerPartyContact(SalesHeader: Record "Sales Header"; Customer: Record Customer; var CustContactID: Text; var CustContactName: Text; var CustContactTelephone: Text; var CustContactTelefax: Text; var CustContactElectronicMail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAdditionalDocRefInfo(var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; SalesHeader: Record "Sales Header"; ProcessedDocType: Option Sale,Service; var DocumentAttachments: Record "Document Attachment"; var FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGeneralInfoProcedure(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLNDeliveryInfo(SalesHeader: Record "Sales Header"; var ActualDeliveryDate: Text; var DeliveryID: Text; var DeliveryIDSchemeID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeliveryPartyName(SalesHeader: Record "Sales Header"; var DeliveryPartyNameValue: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLegalMonetaryInfoWithInvRounding(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var TaxExclusiveAmount: Text; var TaxInclusiveAmount: Text; var AllowanceTotalAmount: Text; var ChargeTotalAmount: Text; var PrepaidAmount: Text; var PayableRoundingAmount: Text; var PayableAmount: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var InvoiceLineAccountingCost: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var BaseQuantity: Text; var UnitCode: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansPayeeFinancialAcc(CompanyInfo: Record "Company Information"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var SubtotalTaxAmount: Text; var TransactionCurrencyTaxAmount: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalsOnBeforeInsertVATAmtLine(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyLegalEntityByFormat(var PartyLegalEntityRegName: Text; var PartyLegalEntityCompanyID: Text; var PartyLegalEntitySchemeID: Text; var SupplierRegAddrCityName: Text; var SupplierRegAddrCountryIdCode: Text; var SupplRegAddrCountryIdListId: Text; IsBISBilling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferHeaderToSalesHeader(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecRefTransferFieldsOnTransferLineToSalesLine(FromRecord: Variant; var ToRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyInfoByFormat(var SupplierEndpointID: Text; var SupplierSchemeID: Text; var SupplierName: Text; IsBISBilling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountingSupplierPartyIdentificationID(SalesHeader: Record "Sales Header"; var PartyIdentificationID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBuyerReference(SalesHeader: Record "Sales Header"; var BuyerReference: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var Filename: Text; var EmbeddedDocumentBinaryObject: Text; var IsHandled: Boolean)
    begin
    end;
}

