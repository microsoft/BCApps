// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.EServices.EDocument;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Email;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 452 "Report Distribution Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        HideDialog: Boolean;
        SalesInvoiceDocTypeTxt: Label 'Sales Invoice';
        SalesCrMemoDocTypeTxt: Label 'Sales Credit Memo';
        SalesQuoteDocTypeTxt: Label 'Sales Quote';
        SalesOrderDocTypeTxt: Label 'Sales Order';
        SalesBlanketOrderDocTypeTxt: Label 'Sales Blanket Order';
        SalesReturnOrderDocTypeTxt: Label 'Sales Return Order';
        SalesShipmentDocTypeTxt: Label 'Sales Shipment';
        SalesReturnRcptDocTypeTxt: Label 'Sales Receipt';
        PurchaseInvoiceDocTypeTxt: Label 'Purchase Invoice';
        PurchaseCrMemoDocTypeTxt: Label 'Purchase Credit Memo';
        PurchaseQuoteDocTypeTxt: Label 'Purchase Quote';
        PurchaseOrderDocTypeTxt: Label 'Purchase Order';
        PurchaseBlanketOrderDocTypeTxt: Label 'Purchase Blanket Order';
        PurchaseReturnOrderDocTypeTxt: Label 'Purchase Return Order';
        JobQuoteDocTypeTxt: Label 'Project Quote';
        JobTaskQuoteDocTypeTxt: Label 'Project No %1 Project Task';
        IssuedReminderDocTypeTxt: Label 'Issued Reminder';
        IssuedFinChargeMemoDocTypeTxt: Label 'Issued Finance Charge Memo';

    [Scope('OnPrem')]
    procedure VANDocumentReport(HeaderDoc: Variant; TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        RecordExportBuffer: Record "Record Export Buffer";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        SpecificRecordRef: RecordRef;
        ClientFileName: Text[250];
    begin
        OnBeforeVANDocumentReport(HeaderDoc, TempDocumentSendingProfile, ElectronicDocumentFormat);
        RecordRef.GetTable(HeaderDoc);
        if RecordRef.FindSet() then
            repeat
                OnVANDocumentReportOnBeforeLoopIteration(RecordRef, HeaderDoc);
                SpecificRecordRef.Get(RecordRef.RecordId);
                SpecificRecordRef.SetRecFilter();
                ElectronicDocumentFormat.SendElectronically(
                    TempBlob, ClientFileName, SpecificRecordRef, TempDocumentSendingProfile."Electronic Format");
                if ElectronicDocumentFormat."Delivery Codeunit ID" = 0 then
                    DocExchServiceMgt.SendDocument(SpecificRecordRef, TempBlob)
                else begin
                    RecordExportBuffer.RecordID := SpecificRecordRef.RecordId;
                    RecordExportBuffer.ClientFileName := ClientFileName;
                    RecordExportBuffer.SetFileContent(TempBlob);
                    RecordExportBuffer."Electronic Document Format" := TempDocumentSendingProfile."Electronic Format";
                    RecordExportBuffer."Document Sending Profile" := TempDocumentSendingProfile.Code;
                    OnVANDocumentReportOnBeforeRunDeliveryCodeunit(RecordExportBuffer);
                    CODEUNIT.Run(ElectronicDocumentFormat."Delivery Codeunit ID", RecordExportBuffer);
                end;
            until RecordRef.Next() = 0;
    end;

    procedure DownloadPdfOnClient(ServerPdfFilePath: Text): Text
    var
        FileManagement: Codeunit "File Management";
        ClientPdfFilePath: Text;
    begin
        ClientPdfFilePath := FileManagement.DownloadTempFile(ServerPdfFilePath);
        Erase(ServerPdfFilePath);
        exit(ClientPdfFilePath);
    end;

    procedure InitializeFrom(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure GetFullDocumentTypeText(DocumentVariant: Variant) DocumentTypeText: Text[50]
    var
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        TranslationHelper: Codeunit "Translation Helper";
        DocumentRecordRef: RecordRef;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        TranslationHelper.SetGlobalLanguageByCode(GetDocumentLanguageCode(DocumentVariant));

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                DocumentTypeText := SalesInvoiceDocTypeTxt;
            DATABASE::"Sales Cr.Memo Header":
                DocumentTypeText := SalesCrMemoDocTypeTxt;
            Database::"Sales Shipment Header":
                DocumentTypeText := SalesShipmentDocTypeTxt;
            Database::"Purch. Inv. Header":
                DocumentTypeText := PurchaseInvoiceDocTypeTxt;
            Database::"Purch. Cr. Memo Hdr.":
                DocumentTypeText := PurchaseCrMemoDocTypeTxt;
            DATABASE::Job:
                DocumentTypeText := JobQuoteDocTypeTxt;
            Database::"Return Receipt Header":
                DocumentTypeText := SalesReturnRcptDocTypeTxt;
            Database::"Issued Reminder Header":
                DocumentTypeText := IssuedReminderDocTypeTxt;
            Database::"Issued Fin. Charge Memo Header":
                DocumentTypeText := IssuedFinChargeMemoDocTypeTxt;
            DATABASE::"Sales Header":
                begin
                    DocumentRecordRef.SetTable(SalesHeader);
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Invoice:
                            DocumentTypeText := SalesInvoiceDocTypeTxt;
                        SalesHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := SalesCrMemoDocTypeTxt;
                        SalesHeader."Document Type"::Quote:
                            DocumentTypeText := SalesQuoteDocTypeTxt;
                        SalesHeader."Document Type"::Order:
                            DocumentTypeText := SalesOrderDocTypeTxt;
                        SalesHeader."Document Type"::"Blanket Order":
                            DocumentTypeText := SalesBlanketOrderDocTypeTxt;
                        SalesHeader."Document Type"::"Return Order":
                            DocumentTypeText := SalesReturnOrderDocTypeTxt;
                    end;
                end;
            DATABASE::"Purchase Header":
                begin
                    DocumentRecordRef.SetTable(PurchaseHeader);
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Invoice:
                            DocumentTypeText := PurchaseInvoiceDocTypeTxt;
                        PurchaseHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := PurchaseCrMemoDocTypeTxt;
                        PurchaseHeader."Document Type"::Quote:
                            DocumentTypeText := PurchaseQuoteDocTypeTxt;
                        PurchaseHeader."Document Type"::Order:
                            DocumentTypeText := PurchaseOrderDocTypeTxt;
                        PurchaseHeader."Document Type"::"Blanket Order":
                            DocumentTypeText := PurchaseBlanketOrderDocTypeTxt;
                        PurchaseHeader."Document Type"::"Return Order":
                            DocumentTypeText := PurchaseReturnOrderDocTypeTxt;
                    end;
                end;
            DATABASE::"Job Task":
                begin
                    DocumentRecordRef.SetTable(JobTask);
                    DocumentTypeText := (StrSubstNo(JobTaskQuoteDocTypeTxt, JobTask."Job No."));
                end;
            else
                OnGetFullDocumentTypeTextElseCase(DocumentRecordRef, DocumentTypeText);
        end;

        TranslationHelper.RestoreGlobalLanguage();

        OnAfterGetFullDocumentTypeText(DocumentVariant, DocumentTypeText, DocumentRecordRef);
    end;

    procedure GetDocumentLanguageCode(DocumentVariant: Variant) LanguageCode: Code[10]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        DocumentRecordRef: RecordRef;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    exit(SalesInvoiceHeader."Language Code");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentRecordRef.SetTable(SalesCrMemoHeader);
                    exit(SalesCrMemoHeader."Language Code");
                end;
            DATABASE::"Sales Header":
                begin
                    DocumentRecordRef.SetTable(SalesHeader);
                    exit(SalesHeader."Language Code");
                end;
            DATABASE::"Purchase Header":
                begin
                    DocumentRecordRef.SetTable(PurchaseHeader);
                    exit(PurchaseHeader."Language Code");
                end;
            DATABASE::Job:
                begin
                    DocumentRecordRef.SetTable(Job);
                    exit(Job."Language Code");
                end;
            DATABASE::"Job Task":
                begin
                    DocumentRecordRef.SetTable(JobTask);
                    exit(JobTask."Language Code");
                end;
            else
                OnGetDocumentLanguageCodeCaseElse(DocumentRecordRef, LanguageCode);
        end;
    end;

    procedure GetReportCaption(ReportID: Integer; LanguageCode: Code[10]) ReportCaption: Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TranslationHelper: Codeunit "Translation Helper";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReportCaption(ReportID, LanguageCode, ReportCaption, IsHandled);
        if IsHandled then
            exit;

        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID) then
            ReportCaption := AllObjWithCaption."Object Caption";

        TranslationHelper.RestoreGlobalLanguage();
    end;

    local procedure GetBillToCustomer(var Customer: Record Customer; DocumentVariant: Variant)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        Job: Record Job;
        DocumentRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBillToCustomer(Customer, DocumentVariant, IsHandled);
        if IsHandled then
            exit;

        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
                end;
            DATABASE::"Sales Header":
                begin
                    SalesHeader := DocumentVariant;
                    Customer.Get(SalesHeader."Bill-to Customer No.");
                end;
            DATABASE::Job:
                begin
                    Job := DocumentVariant;
                    Customer.Get(Job."Bill-to Customer No.");
                end;
            else
                OnGetBillToCustomerOnUnhandledTableNo(DocumentRecordRef, Customer);
        end;

        OnAfterGetBillToCustomer(Customer, DocumentVariant, DocumentRecordRef);
    end;

    local procedure GetBuyFromVendor(var Vendor: Record Vendor; DocumentVariant: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentRecordRef: RecordRef;
    begin
        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Purchase Header":
                begin
                    PurchaseHeader := DocumentVariant;
                    Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
                end;
        end;
    end;

    procedure SaveFileOnClient(var TempBlob: Codeunit "Temp Blob"; ClientFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.BLOBExport(TempBlob, ClientFileName, true);
    end;

    local procedure SendAttachment(PostedDocumentNo: Code[20]; SendEmailAddress: Text[250]; var AttachmentTempBlob: Codeunit "Temp Blob"; AttachmentFileName: Text[250]; DocumentVariant: Variant; SendTo: Enum "Doc. Sending Profile Send To"; var EmailBodyTempBlob: Codeunit "Temp Blob"; ReportUsage: Enum "Report Selection Usage"; var ReceiverRecord: RecordRef)
    var
        DocumentMailing: Codeunit "Document-Mailing";
        FileManagement: Codeunit "File Management";
        SourceReference: RecordRef;
        DocumentType: Text[50];
        AttachmentStream: Instream;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        DocumentType := GetFullDocumentTypeText(DocumentVariant);

        if SendTo = SendTo::Disk then begin
            FileManagement.BLOBExport(AttachmentTempBlob, AttachmentFileName, true);
            exit;
        end;

        if AttachmentTempBlob.HasValue() then
            AttachmentTempBlob.CreateInStream(AttachmentStream);
        SourceReference.GetTable(DocumentVariant);

        SourceTableIDs.Add(SourceReference.Number());
        SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo()).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        SourceTableIDs.Add(ReceiverRecord.Number());
        SourceIDs.Add(SourceReference.Field(ReceiverRecord.SystemIdNo()).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());

        DocumentMailing.EmailFile(
          AttachmentStream, AttachmentFileName, EmailBodyTempBlob, PostedDocumentNo,
          SendEmailAddress, DocumentType, HideDialog, ReportUsage.AsInteger(), SourceTableIDs, SourceIDs, SourceRelationTypes);
    end;

    internal procedure GetIssuedReminderDocTypeTxt(): Text
    begin
        exit(IssuedReminderDocTypeTxt);
    end;

#if not CLEAN27
    [Scope('OnPrem')]
    [Obsolete('Replaced with SendXmlEmailAttachment that accepts a TempBlob as additional parameter.', '27.0')]
    procedure SendXmlEmailAttachment(DocumentVariant: Variant; DocumentFormat: Code[20]; ServerEmailBodyFilePath: Text[250]; SendToEmailAddress: Text[250]; ReportUsage: Enum "Report Selection Usage")
    var
        FileManagement: Codeunit "File Management";
        EmailBodyTempBlob: Codeunit "Temp Blob";
    begin
        if ServerEmailBodyFilePath <> '' then
            FileManagement.BLOBImportFromServerFile(EmailBodyTempBlob, ServerEmailBodyFilePath);
        SendXmlEmailAttachment(DocumentVariant, DocumentFormat, EmailBodyTempBlob, SendToEmailAddress, ReportUsage);
    end;
#endif

    procedure SendXmlEmailAttachment(DocumentVariant: Variant; DocumentFormat: Code[20]; var EmailBodyTempBlob: Codeunit "Temp Blob"; SendToEmailAddress: Text[250]; ReportUsage: Enum "Report Selection Usage")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        ReceiverRecord: RecordRef;
        ClientFileName: Text[250];
    begin
        OnBeforeSendXmlEmailAttachment(ElectronicDocumentFormat, Customer, DocumentSendingProfile);

        GetBillToCustomer(Customer, DocumentVariant);

        if SendToEmailAddress = '' then
            SendToEmailAddress := DocumentMailing.GetToAddressFromCustomer(Customer."No.");

        DocumentSendingProfile.Get(Customer."Document Sending Profile");
        if DocumentSendingProfile.Usage = "Document Sending Profile Usage"::"Job Quote" then
            ReportUsage := ReportSelections.Usage::JQ;

        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, DocumentFormat);
        Commit();
        ReceiverRecord.Open(Database::Customer);
        ReceiverRecord.GetBySystemId(Customer.SystemId);
        SendAttachment(
          ElectronicDocumentFormat.GetDocumentNo(DocumentVariant),
          SendToEmailAddress,
          TempBlob,
          ClientFileName,
          DocumentVariant,
          Enum::"Doc. Sending Profile Send To"::"Electronic Document",
          EmailBodyTempBlob, ReportUsage, ReceiverRecord);
    end;

#if not CLEAN27
    [Scope('OnPrem')]
    [Obsolete('Replaced with SendXmlEmailAttachmentVendor that accepts a TempBlob as additional parameter.', '27.0')]
    procedure SendXmlEmailAttachmentVendor(DocumentVariant: Variant; DocumentFormat: Code[20]; ServerEmailBodyFilePath: Text[250]; SendToEmailAddress: Text[250])
    var
        FileManagement: Codeunit "File Management";
        EmailBodyTempBlob: Codeunit "Temp Blob";
    begin
        if ServerEmailBodyFilePath <> '' then
            FileManagement.BLOBImportFromServerFile(EmailBodyTempBlob, ServerEmailBodyFilePath);
        SendXmlEmailAttachmentVendor(DocumentVariant, DocumentFormat, EmailBodyTempBlob, SendToEmailAddress);
    end;
#endif

    procedure SendXmlEmailAttachmentVendor(DocumentVariant: Variant; DocumentFormat: Code[20]; var EmailBodyTempBlob: Codeunit "Temp Blob"; SendToEmailAddress: Text[250])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Vendor: Record Vendor;
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        ReceiverRecord: RecordRef;
        ClientFileName: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        GetBuyFromVendor(Vendor, DocumentVariant);

        if SendToEmailAddress = '' then
            SendToEmailAddress := DocumentMailing.GetToAddressFromVendor(Vendor."No.");

        DocumentSendingProfile.Get(Vendor."Document Sending Profile");
        if DocumentSendingProfile.Usage = "Document Sending Profile Usage"::"Job Quote" then
            ReportUsage := ReportSelections.Usage::JQ;

        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, DocumentFormat);
        Commit();
        ReceiverRecord.Open(Database::Vendor);
        ReceiverRecord.GetBySystemId(Vendor.SystemId);
        SendAttachment(
          ElectronicDocumentFormat.GetDocumentNo(DocumentVariant),
          SendToEmailAddress,
          TempBlob,
          ClientFileName,
          DocumentVariant,
          Enum::"Doc. Sending Profile Send To"::"Electronic Document",
          EmailBodyTempBlob, ReportUsage, ReceiverRecord);
    end;

    [Scope('OnPrem')]
    procedure RunDefaultCheckSalesElectronicDocument(SalesHeader: Record "Sales Header")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunDefaultCheckSalesElectronicDocument(SalesHeader, IsHandled);
        if IsHandled then
            exit;
        GetElectronicDocumentFormat(ElectronicDocumentFormat, SalesHeader);

        ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, ElectronicDocumentFormat.Code);
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit "Serv. Report Distribution Mgt."', '25.0')]
    procedure RunDefaultCheckServiceElectronicDocument(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        GetElectronicDocumentFormat(ElectronicDocumentFormat, ServiceHeader);
        ElectronicDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, ElectronicDocumentFormat.Code);
    end;
#endif

    procedure GetElectronicDocumentFormat(var ElectronicDocumentFormat: Record "Electronic Document Format"; DocumentVariant: Variant)
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        GetBillToCustomer(Customer, DocumentVariant);

        if not DocumentSendingProfile.Get(Customer."Document Sending Profile") then
            exit;

        if DocumentSendingProfile.Disk in
           [DocumentSendingProfile.Disk::"Electronic Document", DocumentSendingProfile.Disk::"PDF & Electronic Document"]
        then
            if not ElectronicDocumentFormat.Get(DocumentSendingProfile."Disk Format") then
                exit;

        if DocumentSendingProfile."Electronic Document" = DocumentSendingProfile."Electronic Document"::"Through Document Exchange Service" then
            if not ElectronicDocumentFormat.Get(DocumentSendingProfile."Electronic Format") then
                exit;
    end;

    [Scope('OnPrem')]
    procedure CreateOrAppendZipFile(var DataCompression: Codeunit "Data Compression"; var ServerTempBlob: Codeunit "Temp Blob"; ClientFileName: Text[250]; var ClientZipFileName: Text[250])
    var
        FileManagement: Codeunit "File Management";
        FileContentInStream: InStream;
        IsGZip: Boolean;
    begin
        ServerTempBlob.CreateInStream(FileContentInStream);
        IsGZip := DataCompression.IsGZip(FileContentInStream);
        if IsGZip then begin
            DataCompression.OpenZipArchive(FileContentInStream, true);
            ClientZipFileName := ClientFileName;
        end else begin
            DataCompression.CreateZipArchive();
            DataCompression.AddEntry(FileContentInStream, ClientFileName);
            ClientZipFileName := CopyStr(FileManagement.GetFileNameWithoutExtension(ClientFileName) + '.zip', 1, 250);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunDefaultCheckSalesElectronicDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBillToCustomer(var Customer: Record Customer; DocumentVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReportCaption(ReportID: Integer; LanguageCode: Code[10]; var ReportCaption: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendXmlEmailAttachment(var ElectronicDocumentFormat: Record "Electronic Document Format"; var Customer: Record Customer; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVANDocumentReport(HeaderDoc: Variant; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var ElectronicDocumentFormat: Record "Electronic Document Format");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBillToCustomer(var Customer: Record Customer; DocumentVariant: Variant; DocumentRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFullDocumentTypeText(DocumentVariant: Variant; var DocumentTypeText: Text[50]; var DocumentRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentLanguageCodeCaseElse(DocumentRecordRef: RecordRef; var LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVANDocumentReportOnBeforeLoopIteration(var RecordRef: RecordRef; var HeaderDoc: Variant);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVANDocumentReportOnBeforeRunDeliveryCodeunit(var RecordExportBuffer: Record "Record Export Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBillToCustomerOnUnhandledTableNo(DocumentRecordRef: RecordRef; var Customer: Record Customer)
    begin
    end;
}

