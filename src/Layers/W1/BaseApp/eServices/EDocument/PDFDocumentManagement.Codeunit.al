// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.EMail;
using System.Utilities;

codeunit 5467 "PDF Document Management"
{

    trigger OnRun()
    begin
    end;

    var
        CannotFindDocumentErr: Label 'The document %1 cannot be found.', Comment = '%1 - Error Message';
        CannotOpenFileErr: Label 'Opening the file failed because of the following error: \%1.', Comment = '%1 - Error Message';
        UnpostedSalesCreditMemoErr: Label 'You must post sales credit memo %1 before generating the PDF document.', Comment = '%1 - sales credit memo id';
        UnpostedPurchaseCreditMemoErr: Label 'You must post purchase credit memo %1 before generating the PDF document.', Comment = '%1 - purchase credit memo id';
        UnpostedPurchaseInvoiceErr: Label 'You must post purchase invoice %1 before generating the PDF document.', Comment = '%1 - sales credit memo id';
        CannotFindContactErr: Label 'The Contact cannot be found with SystemtId %1,', Comment = '%1 - Contact System id';
        BlobEmptyErr: Label 'Opening the file failed.';
        CreditMemoTxt: Label 'Credit Memo';
        CustomerStatementTxt: Label 'Customer Statement';
        PurchaseInvoiceTxt: Label 'Purchase Invoice';

    [Scope('OnPrem')]
    procedure GeneratePdf(DocumentId: Guid; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        File: File;
        InStream: InStream;
        OutStream: OutStream;
        Path: Text[250];
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
        DocumentFound: Boolean;
    begin
        CompanyInformation.Get();
        if SalesHeader.GetBySystemId(DocumentId) then begin
            SalesHeader.SetRange("No.", SalesHeader."No.");
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type");

            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice:
                    begin
                        ReportUsage := "Report Selection Usage"::"S.Invoice Draft";
                        ReportSelections.GetPdfReportForCust(Path, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                    end;
                SalesHeader."Document Type"::Quote:
                    begin
                        ReportUsage := "Report Selection Usage"::"S.Quote";
                        ReportSelections.GetPdfReportForCust(Path, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                    end;
                SalesHeader."Document Type"::"Credit Memo":
                    Error(UnpostedSalesCreditMemoErr, DocumentId);
                else
                    Error(CannotFindDocumentErr, DocumentId);
            end;
            DocumentFound := true;
        end;

        if not DocumentFound then
            if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentId, SalesInvoiceHeader) then begin
                SalesInvoiceHeader.SetRange("No.", SalesInvoiceHeader."No.");
                ReportUsage := "Report Selection Usage"::"S.Invoice";
                ReportSelections.GetPdfReportForCust(Path, ReportUsage, SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
                DocumentMailing.GetAttachmentFileName(Name, SalesInvoiceHeader."No.", SalesInvoiceHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                DocumentFound := true;
            end;

        if not DocumentFound then
            if GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderFromId(DocumentId, SalesCrMemoHeader) then begin
                SalesCrMemoHeader.SetRange("No.", SalesCrMemoHeader."No.");
                ReportUsage := "Report Selection Usage"::"S.Cr.Memo";
                ReportSelections.GetPdfReportForCust(Path, ReportUsage, SalesCrMemoHeader, SalesCrMemoHeader."Sell-to Customer No.");
                DocumentMailing.GetAttachmentFileName(Name, SalesCrMemoHeader."No.", CreditMemoTxt, ReportUsage.AsInteger());
                DocumentFound := true;
            end;

        if not DocumentFound then
            if PurchaseHeader.GetBySystemId(DocumentId) and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice) then
                Error(UnpostedPurchaseInvoiceErr, DocumentId);

        if not DocumentFound then
            if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentId, PurchInvHeader) then begin
                PurchInvHeader.SetRange("No.", PurchInvHeader."No.");
                ReportUsage := "Report Selection Usage"::"P.Invoice";
                ReportSelections.GetPdfReportForCust(Path, ReportUsage, PurchInvHeader, PurchInvHeader."Buy-from Vendor No.");
                DocumentMailing.GetAttachmentFileName(Name, PurchInvHeader."No.", PurchaseInvoiceTxt, ReportUsage.AsInteger());
                DocumentFound := true;
            end;

        if not DocumentFound then
            Error(CannotFindDocumentErr, DocumentId);

        if not File.Open(Path) then
            Error(CannotOpenFileErr, GetLastErrorText);

        TempAttachmentEntityBuffer.Init();
        TempAttachmentEntityBuffer.Id := DocumentId;
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := Name;
        TempAttachmentEntityBuffer.Type := TempAttachmentEntityBuffer.Type::PDF;
        TempAttachmentEntityBuffer.Content.CreateOutStream(OutStream);
        File.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        File.Close();
        if Erase(Path) then;
        TempAttachmentEntityBuffer.Insert(true);

        exit(true);
    end;

    procedure GeneratePdfBlobWithDocumentType(ParentId: Guid; DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    begin
        if GeneratePdfBlobWithDocumentType(DocumentId, DocumentType, TempAttachmentEntityBuffer) then begin
            TempAttachmentEntityBuffer.Rename(TempAttachmentEntityBuffer.Id, ParentId);
            TempAttachmentEntityBuffer.Modify();
            exit(true);
        end;
    end;

    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelections: Record "Report Selections";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        DocumentMailing: Codeunit "Document-Mailing";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
        DocumentFound: Boolean;
    begin
        CompanyInformation.Get();

        case DocumentType of
            DocumentType::Journal, DocumentType::" ":
                DocumentFound := false;
            DocumentType::"Sales Order":
                if SalesHeader.GetBySystemId(DocumentId) then begin
                    SalesHeader.SetRange("No.", SalesHeader."No.");
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
                    ReportUsage := "Report Selection Usage"::"S.Order";
                    ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                    DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                    DocumentFound := true;
                end;
            DocumentType::"Sales Quote":
                if SalesHeader.GetBySystemId(DocumentId) then
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then begin
                        SalesHeader.SetRange("No.", SalesHeader."No.");
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
                        ReportUsage := "Report Selection Usage"::"S.Quote";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
            DocumentType::"Sales Invoice":
                begin
                    if SalesHeader.GetBySystemId(DocumentId) then
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
                            SalesHeader.SetRange("No.", SalesHeader."No.");
                            SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
                            ReportUsage := "Report Selection Usage"::"S.Invoice Draft";
                            ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                            DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                            DocumentFound := true;
                        end;
                    if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentId, SalesInvoiceHeader) then begin
                        SalesInvoiceHeader.SetRange("No.", SalesInvoiceHeader."No.");
                        ReportUsage := "Report Selection Usage"::"S.Invoice";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesInvoiceHeader."No.", SalesInvoiceHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
                end;
            DocumentType::"Sales Credit Memo":
                begin
                    if SalesHeader.GetBySystemId(DocumentId) then
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            Error(UnpostedSalesCreditMemoErr, DocumentId);
                    if GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderFromId(DocumentId, SalesCrMemoHeader) then begin
                        SalesCrMemoHeader.SetRange("No.", SalesCrMemoHeader."No.");
                        ReportUsage := "Report Selection Usage"::"S.Cr.Memo";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesCrMemoHeader, SalesCrMemoHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesCrMemoHeader."No.", CreditMemoTxt, ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
                end;
            DocumentType::"Customer Statement":
                begin
                    if not Contact.GetBySystemId(DocumentId) then
                        error(CannotFindContactErr, DocumentId);
                    Clear(Customer);
                    ContactBusinessRelation.SetRange("Contact No.", Contact."Company No.");
                    ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                    if ContactBusinessRelation.FindFirst() then begin
                        Customer.Get(ContactBusinessRelation."No.");
                        Customer.SetRange("No.", Customer."No.");
                        ReportUsage := "Report Selection Usage"::"C.Statement";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, Customer, Customer."No.");
                        DocumentMailing.GetAttachmentFileName(Name, Customer."No.", CustomerStatementTxt, ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
                end;
            DocumentType::"Purchase Invoice":
                begin
                    if PurchaseHeader.GetBySystemId(DocumentId) then
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
                            Error(UnpostedPurchaseInvoiceErr, DocumentId);
                    if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentId, PurchInvHeader) then begin
                        PurchInvHeader.SetRange("No.", PurchInvHeader."No.");
                        ReportUsage := "Report Selection Usage"::"P.Invoice";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, PurchInvHeader, PurchInvHeader."Buy-from Vendor No.");
                        DocumentMailing.GetAttachmentFileName(Name, PurchInvHeader."No.", PurchaseInvoiceTxt, ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
                end;
            DocumentType::"Purchase Credit Memo":
                begin
                    if PurchaseHeader.GetBySystemId(DocumentId) then
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                            Error(UnpostedPurchaseCreditMemoErr, DocumentId);
                    if GraphMgtPurchCrMemo.GetPurchaseCrMemoHeaderFromId(DocumentId, PurchCrMemoHdr) then begin
                        PurchCrMemoHdr.SetRange("No.", PurchCrMemoHdr."No.");
                        ReportUsage := "Report Selection Usage"::"P.Cr.Memo";
                        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, PurchCrMemoHdr, PurchCrMemoHdr."Buy-from Vendor No.");
                        DocumentMailing.GetAttachmentFileName(Name, PurchCrMemoHdr."No.", CreditMemoTxt, ReportUsage.AsInteger());
                        DocumentFound := true;
                    end;
                end;
        end;

        if not DocumentFound then
            Error(CannotFindDocumentErr, DocumentId);

        if not TempBlob.HasValue() then
            Error(BlobEmptyErr);

        TempAttachmentEntityBuffer.Init();
        TempAttachmentEntityBuffer.Id := DocumentId;
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := Name;
        TempAttachmentEntityBuffer."Document Type" := DocumentType;
        TempAttachmentEntityBuffer.Type := TempAttachmentEntityBuffer.Type::PDF;
        TempAttachmentEntityBuffer.Content.CreateOutStream(OutStream);
        TempBlob.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        TempAttachmentEntityBuffer.Insert(true);

        exit(true);
    end;
}
