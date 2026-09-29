// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using System.EMail;
using System.Utilities;

codeunit 3370 "EDoc CFDI Email MX"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure TrySendStampEmail(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service")
    var
        Customer: Record Customer;
        EDocDataStorage: Record "E-Doc. Data Storage";
        Email: Codeunit Email;
        Message: Codeunit "Email Message";
        TempBlobPDF: Codeunit "Temp Blob";
        EmailAccount: Record "Email Account";
        EmailScenario: Codeunit "Email Scenario";
        Recipients: List of [Text];
        XMLInStream: InStream;
        PDFInStream: InStream;
        CustomerEmail: Text;
        DocNo: Code[20];
    begin
        if not EDocumentService."Send PDF Report" then
            exit;

        if EDocument."Bill-to/Pay-to No." = '' then
            exit;

        if not Customer.Get(EDocument."Bill-to/Pay-to No.") then
            exit;

        CustomerEmail := Customer."E-Mail";
        if CustomerEmail = '' then begin
            Session.LogMessage('0000QXB', StrSubstNo(NoCustomerEmailMsg, EDocument."Bill-to/Pay-to No."), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            exit;
        end;

        if EDocument."Structured Data Entry No." = 0 then
            exit;
        if not EDocDataStorage.Get(EDocument."Structured Data Entry No.") then
            exit;
        EDocDataStorage.CalcFields("Data Storage");
        if not EDocDataStorage."Data Storage".HasValue() then
            exit;

        DocNo := CopyStr(EDocument."Document No.", 1, MaxStrLen(DocNo));
        Recipients.Add(CustomerEmail);
        Message.Create(Recipients, StrSubstNo(EmailSubjectTxt, DocNo), StrSubstNo(EmailBodyTxt, EDocument."Bill-to/Pay-to Name", DocNo), true);

        EDocDataStorage."Data Storage".CreateInStream(XMLInStream, TextEncoding::UTF8);
        Message.AddAttachment(DocNo + '.xml', 'text/xml', XMLInStream);

        if TryGeneratePDF(EDocument, TempBlobPDF) then begin
            TempBlobPDF.CreateInStream(PDFInStream);
            Message.AddAttachment(DocNo + '.pdf', 'application/pdf', PDFInStream);
        end;

        if not EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount) then begin
            Session.LogMessage('0000QXC', NoEmailAccountMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            exit;
        end;

        if not Email.Send(Message, EmailAccount."Account Id", EmailAccount.Connector) then
            Session.LogMessage('0000QXD', StrSubstNo(SendEmailFailedMsg, GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
    end;

    local procedure TryGeneratePDF(EDocument: Record "E-Document"; var TempBlobPDF: Codeunit "Temp Blob"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ReportSelections: Record "Report Selections";
        RecordRef: RecordRef;
        RecordVariant: Variant;
        ReportUsage: Enum "Report Selection Usage";
    begin
        if EDocument."Document Record ID".TableNo() = 0 then
            exit(false);
        if not RecordRef.Get(EDocument."Document Record ID") then
            exit(false);

        case RecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvoiceHeader);
                    RecordVariant := SalesInvoiceHeader;
                    ReportUsage := Enum::"Report Selection Usage"::"S.Invoice";
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecordRef.SetTable(SalesCrMemoHeader);
                    RecordVariant := SalesCrMemoHeader;
                    ReportUsage := Enum::"Report Selection Usage"::"S.Cr.Memo";
                end;
            Database::"Service Invoice Header":
                begin
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    RecordVariant := ServiceInvoiceHeader;
                    ReportUsage := Enum::"Report Selection Usage"::"SM.Invoice";
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    RecordVariant := ServiceCrMemoHeader;
                    ReportUsage := Enum::"Report Selection Usage"::"SM.Credit Memo";
                end;
            else
                exit(false);
        end;

        ReportSelections.GetPdfReportForCust(TempBlobPDF, ReportUsage, RecordVariant, EDocument."Bill-to/Pay-to No.");
        exit(TempBlobPDF.HasValue());
    end;

    var
        FeatureNameTxt: Label 'CFDI Email';
        EmailSubjectTxt: Label 'Electronic Document (CFDI) %1', Comment = '%1 = Document No.';
        EmailBodyTxt: Label 'Dear %1,<br/><br/>Please find attached your CFDI electronic document %2.<br/><br/>Regards,', Comment = '%1 = Customer name, %2 = Document No.';
        NoCustomerEmailMsg: Label 'Customer %1 has no email address. Stamped CFDI email was not sent.', Locked = true;
        NoEmailAccountMsg: Label 'No default email account configured. Stamped CFDI email was not sent.', Locked = true;
        SendEmailFailedMsg: Label 'Failed to send stamped CFDI email: %1', Locked = true;
}
