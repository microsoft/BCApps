// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Service.History;
using System.IO;
using System.Telemetry;
using System.Utilities;

codeunit 10983 "Export Factur-X Document"
{
    TableNo = "Record Export Buffer";

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureNameTok: Label 'E-document Factur-X FR Format', Locked = true;
        StartEventNameTok: Label 'E-document Factur-X FR export started', Locked = true;
        EndEventNameTok: Label 'E-document Factur-X FR export completed', Locked = true;

    trigger OnRun()
    begin
        ExportDocument(Rec);
    end;

    procedure ExportDocument(var RecordExportBuffer: Record "Record Export Buffer")
    var
        FRFacturXReportIntegration: Codeunit "Factur-X Report Integration";
    begin
        BindSubscription(FRFacturXReportIntegration);
        ExportSalesDocument(RecordExportBuffer);
        UnbindSubscription(FRFacturXReportIntegration);
    end;

    procedure IsFacturXFRPrintProcess() Result: Boolean
    begin
        Result := false;
        OnIsFacturXFRPrintProcess(Result);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var SalesInvoiceHeader: Record "Sales Invoice Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        InitEDocument(EDocument, SalesInvoiceHeader."No.", SalesInvoiceHeader."Document Date",
                      SalesInvoiceHeader."Currency Code", SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT");

        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceDocumentLines.GetTable(SalesInvoiceLine);

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        InitEDocument(EDocument, SalesCrMemoHeader."No.", SalesCrMemoHeader."Document Date",
                      SalesCrMemoHeader."Currency Code", SalesCrMemoHeader.Amount, SalesCrMemoHeader."Amount Including VAT");

        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SourceDocumentLines.GetTable(SalesCrMemoLine);

        CIIXMLBuilder.CreateCreditMemoXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var ServiceInvoiceHeader: Record "Service Invoice Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        ServiceInvoiceLine: Record "Service Invoice Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        InitEDocument(EDocument, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Document Date",
                      ServiceInvoiceHeader."Currency Code", ServiceInvoiceHeader.Amount, ServiceInvoiceHeader."Amount Including VAT");

        SourceDocumentHeader.GetTable(ServiceInvoiceHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        SourceDocumentLines.GetTable(ServiceInvoiceLine);

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        InitEDocument(EDocument, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Document Date",
                      ServiceCrMemoHeader."Currency Code", ServiceCrMemoHeader.Amount, ServiceCrMemoHeader."Amount Including VAT");

        SourceDocumentHeader.GetTable(ServiceCrMemoHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        SourceDocumentLines.GetTable(ServiceCrMemoLine);

        CIIXMLBuilder.CreateCreditMemoXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var IssuedReminderHeader: Record "Issued Reminder Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        IssuedReminderLine: Record "Issued Reminder Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        IssuedReminderHeader.CalcFields("Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
        InitEDocument(EDocument, IssuedReminderHeader."No.", IssuedReminderHeader."Document Date",
                      IssuedReminderHeader."Currency Code",
                      IssuedReminderHeader."Interest Amount" + IssuedReminderHeader."Additional Fee" + IssuedReminderHeader."Add. Fee per Line",
                      IssuedReminderHeader."Interest Amount" + IssuedReminderHeader."Additional Fee" + IssuedReminderHeader."Add. Fee per Line" + IssuedReminderHeader."VAT Amount");

        SourceDocumentHeader.GetTable(IssuedReminderHeader);
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        SourceDocumentLines.GetTable(IssuedReminderLine);

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure CreateAndAddXMLAttachmentToRenderingPayload(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var RenderingPayload: JsonObject)
    var
        EDocument: Record "E-Document";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        IssuedFinChargeMemoHeader.CalcFields("Interest Amount", "Additional Fee", "VAT Amount");
        InitEDocument(EDocument, IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoHeader."Document Date",
                      IssuedFinChargeMemoHeader."Currency Code",
                      IssuedFinChargeMemoHeader."Interest Amount" + IssuedFinChargeMemoHeader."Additional Fee",
                      IssuedFinChargeMemoHeader."Interest Amount" + IssuedFinChargeMemoHeader."Additional Fee" + IssuedFinChargeMemoHeader."VAT Amount");

        SourceDocumentHeader.GetTable(IssuedFinChargeMemoHeader);
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        SourceDocumentLines.GetTable(IssuedFinChargeMemoLine);

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        AddXMLAttachmentToRenderingPayload(TempBlob, RenderingPayload);
    end;

    procedure ExportSalesDocument(var RecordExportBuffer: Record "Record Export Buffer")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        TempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        FileInStream: InStream;
    begin
        FeatureTelemetry.LogUsage('0000EXD', FeatureNameTok, StartEventNameTok);

        case RecordExportBuffer.RecordID.TableNo of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateSalesInvoicePDFAttachment(SalesInvoiceHeader, TempBlob) then
                        exit;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateSalesCrMemoPDFAttachment(SalesCrMemoHeader, TempBlob) then
                        exit;
                end;
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateServiceInvoicePDFAttachment(ServiceInvoiceHeader, TempBlob) then
                        exit;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateServiceCrMemoPDFAttachment(ServiceCrMemoHeader, TempBlob) then
                        exit;
                end;
            Database::"Issued Reminder Header":
                begin
                    IssuedReminderHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateIssuedReminderPDFAttachment(IssuedReminderHeader, TempBlob) then
                        exit;
                end;
            Database::"Issued Fin. Charge Memo Header":
                begin
                    IssuedFinChargeMemoHeader.Get(RecordExportBuffer.RecordID);
                    if not GenerateIssuedFinChargePDFAttachment(IssuedFinChargeMemoHeader, TempBlob) then
                        exit;
                end;
        end;

        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(FileInStream);
        RecordExportBuffer."File Content".CreateOutStream(FileOutStream, TextEncoding::UTF8);
        CopyStream(FileOutStream, FileInStream);
        RecordExportBuffer.Modify();

        FeatureTelemetry.LogUsage('0000EXE', FeatureNameTok, EndEventNameTok);
    end;

    local procedure GenerateSalesInvoicePDFAttachment(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateSalesInvoicePDFAttachment(SalesInvoiceHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        SalesInvoiceHeader.SetRange("No.", SalesInvoiceHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::"S.Invoice",
            SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure GenerateSalesCrMemoPDFAttachment(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateSalesCrMemoPDFAttachment(SalesCrMemoHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        SalesCrMemoHeader.SetRange("No.", SalesCrMemoHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::"S.Cr.Memo",
            SalesCrMemoHeader, SalesCrMemoHeader."Bill-to Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure GenerateServiceInvoicePDFAttachment(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateServiceInvoicePDFAttachment(ServiceInvoiceHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::"SM.Invoice",
            ServiceInvoiceHeader, ServiceInvoiceHeader."Bill-to Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure GenerateServiceCrMemoPDFAttachment(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateServiceCrMemoPDFAttachment(ServiceCrMemoHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        ServiceCrMemoHeader.SetRange("No.", ServiceCrMemoHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::"SM.Credit Memo",
            ServiceCrMemoHeader, ServiceCrMemoHeader."Bill-to Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure GenerateIssuedReminderPDFAttachment(IssuedReminderHeader: Record "Issued Reminder Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateIssuedReminderPDFAttachment(IssuedReminderHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        IssuedReminderHeader.SetRange("No.", IssuedReminderHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::Reminder,
            IssuedReminderHeader, IssuedReminderHeader."Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure GenerateIssuedFinChargePDFAttachment(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateIssuedFinChargePDFAttachment(IssuedFinChargeMemoHeader, TempBlob, IsHandled);
        if IsHandled then
            exit(TempBlob.HasValue());

        IssuedFinChargeMemoHeader.SetRange("No.", IssuedFinChargeMemoHeader."No.");
        ReportSelections.GetPdfReportForCust(
            TempBlob, "Report Selection Usage"::"Fin.Charge",
            IssuedFinChargeMemoHeader, IssuedFinChargeMemoHeader."Customer No.");
        exit(TempBlob.HasValue());
    end;

    local procedure InitEDocument(var EDocument: Record "E-Document"; DocumentNo: Code[20]; DocumentDate: Date; CurrencyCode: Code[10]; AmountExclVAT: Decimal; AmountInclVAT: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        EDocument.Init();
        EDocument."Document No." := DocumentNo;
        EDocument."Document Date" := DocumentDate;

        GeneralLedgerSetup.Get();
        if CurrencyCode <> GeneralLedgerSetup."LCY Code" then
            EDocument."Currency Code" := CurrencyCode;
        EDocument."Amount Excl. VAT" := AmountExclVAT;
        EDocument."Amount Incl. VAT" := AmountInclVAT;
    end;

    local procedure AddXMLAttachmentToRenderingPayload(var XmlAttachmentTempBlob: Codeunit "Temp Blob"; var RenderingPayload: JsonObject)
    var
        PDFDocument: Codeunit "PDF Document";
        DataType: Enum "PDF Attach. Data Relationship";
        XmlInStream: InStream;
        Name: Text;
        MimeType: Text;
        Description: Text;
        DescriptionLbl: Label 'Factur-X electronic invoice XML', Locked = true;
    begin
        PDFDocument.Initialize();
        Name := 'factur-x.xml';
        DataType := Enum::"PDF Attach. Data Relationship"::Alternative;
        MimeType := 'text/xml';
        Description := DescriptionLbl;

        XmlAttachmentTempBlob.CreateInStream(XmlInStream, TextEncoding::UTF8);
        PDFDocument.AddAttachment(Name, DataType, MimeType, XmlInStream, Description, true);

        RenderingPayload := PDFDocument.ToJson(RenderingPayload);
    end;

    [InternalEvent(false)]
    local procedure OnIsFacturXFRPrintProcess(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateSalesInvoicePDFAttachment(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateSalesCrMemoPDFAttachment(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateServiceInvoicePDFAttachment(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateServiceCrMemoPDFAttachment(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateIssuedReminderPDFAttachment(IssuedReminderHeader: Record "Issued Reminder Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateIssuedFinChargePDFAttachment(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;
}
