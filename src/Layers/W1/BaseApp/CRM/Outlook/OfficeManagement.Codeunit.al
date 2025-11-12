// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using System.EMail;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

codeunit 1630 "Office Management"
{
    var
        AddinDeploymentHelper: Codeunit "Add-in Deployment Helper";
        OfficeHostType: DotNet OfficeHostType;
        OfficeAddinTelemetryCategoryTxt: Label 'AL Office Add-in', Locked = true;
        UploadSuccessMsg: Label 'Sent %1 document(s) to the OCR service successfully.', Comment = '%1=number of documents';
        UploadIncomingDocumentSuccessMsg: Label 'Sent %1 document(s) to the Incoming Documents successfully.', Comment = '%1=number of documents';
        UploadAttachmentSuccessMsg: Label 'Attached %1 document(s) successfully.', Comment = '%1=number of documents';
        AddinInitializedTelemetryTxt: Label 'Office add-in initialized%1  Host name: %2%1  Host Type: %3%1  Mode: %4%1  Command: %5', Locked = true;
        ClientExtensionTelemetryTxt: Label 'Invoking client-side extension: %1', Locked = true;
        HandlerCodeunitTelemetryTxt: Label 'Office add-in handler codeunit: %1', Locked = true;
        IncomingDocumentTelemetryTxt: Label 'Creating Incoming Document from Outlook add-in. %1 attachment(s).', Locked = true;
        CodeUnitNotFoundErr: Label 'Cannot find the object that handles integration with Office.';
        CompanyNotSetupErr: Label 'In order to use another company, you must first start the trial, which cannot be done from the Outlook add-in.';
        CannotSendMailThenDownloadErr: Label 'You cannot send the email.\Verify that the email settings are correct.';

    [Scope('OnPrem')]
    procedure InitializeHost(NewOfficeHost: DotNet OfficeHost; NewHostType: Text)
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.InitializeHost(NewOfficeHost, NewHostType);
    end;

    procedure InitializeContext(TempNewOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeHostManagement: Codeunit "Office Host Management";
        TypeHelper: Codeunit "Type Helper";
    begin
        Session.LogMessage('0000ACT', StrSubstNo(AddinInitializedTelemetryTxt,
                TypeHelper.NewLine(),
                GetHostName(),
                GetHostType(),
                Format(TempNewOfficeAddinContext.Mode),
                TempNewOfficeAddinContext.Command), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeAddinTelemetryCategoryTxt);

        OfficeHostManagement.InitializeContext(TempNewOfficeAddinContext);
        OfficeHostManagement.InitializeExchangeObject();
        if AddinDeploymentHelper.CheckVersion(GetHostType(), TempNewOfficeAddinContext.Version) then
            HandleRedirection(TempNewOfficeAddinContext);
    end;

    local procedure HandleRedirection(TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        HandlerCodeunitID: Integer;
    begin
        HandlerCodeunitID := GetHandlerCodeunit(TempOfficeAddinContext);
        Session.LogMessage('0000ACU', StrSubstNo(HandlerCodeunitTelemetryTxt, HandlerCodeunitID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeAddinTelemetryCategoryTxt);
        Codeunit.Run(HandlerCodeunitID, TempOfficeAddinContext);
    end;

    procedure AddRecipient(Name: Text[100]; Email: Text[80])
    begin
        InvokeExtension('addRecipient', Name, Email, '', '');
    end;

    procedure AttachAvailable(): Boolean
    begin
        if not IsAvailable() then
            exit(false);

        exit(GetHostType() in [OfficeHostType.OutlookHyperlink(),
                             OfficeHostType.OutlookItemEdit(),
                             OfficeHostType.OutlookItemRead(),
                             OfficeHostType.OutlookTaskPane()]);
    end;

    procedure AttachDocument(AttachmentStream: Instream; AttachmentName: Text; BodyText: Text; Subject: Text)
    var
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        FileManagement: Codeunit "File Management";
        OutStream: OutStream;
        FileContent: Text;
        File: File;
        ServerFilePath: Text;
    begin
        ServerFilePath := FileManagement.ServerTempFileName(FileManagement.GetExtension(AttachmentName));
        File.Create(ServerFilePath);
        File.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachmentStream);
        File.Close();

        FileContent := GetContent(ServerFilePath);
        OfficeAttachmentManager.Add(FileContent, AttachmentName, BodyText);
        if OfficeAttachmentManager.Ready() then begin
            Commit();
            InvokeExtension('sendAttachment', OfficeAttachmentManager.GetFiles(), OfficeAttachmentManager.GetNames(), OfficeAttachmentManager.GetBody(), Subject);
            OfficeAttachmentManager.Done();
        end;
    end;

    procedure AttachDocument(BodyText: Text; Subject: Text)
    begin
        InvokeExtension('sendAttachment', '', '', BodyText, Subject);
    end;

    procedure ChangeCompany(NewCompany: Text)
    begin
        ChangeCompanyWithPrompt(NewCompany, '');
    end;

    procedure ChangeCompanyWithPrompt(NewCompany: Text; Prompt: Text): Boolean
    var
        Company: Record Company;
        SaaSLogInManagement: Codeunit "SaaS Log In Management";
    begin
        if CompanyName() = NewCompany then
            exit(true);

        if not Company.Get(NewCompany) then
            exit(true);

        if Prompt <> '' then
            if not Confirm(StrSubstNo(Prompt, Company."Display Name")) then
                exit(false);

        if SaaSLogInManagement.ShouldShowTermsAndConditions(CopyStr(NewCompany, 1, 30)) then
            Error(CompanyNotSetupErr);

        InvokeExtension('changeCompany', NewCompany, '', '', '');
        exit(true);
    end;

    procedure CheckForExistingInvoice(CustNo: Code[20]): Boolean
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeInvoice: Record "Office Invoice";
        OfficeInvoiceSelection: Page "Office Invoice Selection";
    begin
        if IsAvailable() then begin
            GetContext(TempOfficeAddinContext);
            OfficeInvoice.SetRange("Item ID", TempOfficeAddinContext."Item ID");
            if not OfficeInvoice.IsEmpty() then begin
                OfficeInvoiceSelection.SetTableView(OfficeInvoice);
                OfficeInvoiceSelection.SetCustomerNo(CustNo);
                OfficeInvoiceSelection.Run();
                exit(true);
            end;
        end;
    end;

    procedure CloseEnginePage()
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.CloseCurrentPage();
    end;

    procedure DisplayOCRUploadSuccessMessage(UploadedDocumentCount: Integer)
    begin
        Message(StrSubstNo(UploadSuccessMsg, UploadedDocumentCount));
    end;

    procedure DisplayIncomingDocumentUploadSuccessMessage(UploadedDocumentCount: Integer)
    begin
        Message(StrSubstNo(UploadIncomingDocumentSuccessMsg, UploadedDocumentCount));
    end;

    procedure DisplayAttachmentUploadSuccessMessage(UploadedDocumentCount: Integer)
    begin
        Message(StrSubstNo(UploadAttachmentSuccessMsg, UploadedDocumentCount));
    end;

    procedure DisplaySuccessMessage(var ExchangeObject: Record "Exchange Object")
    begin
        case ExchangeObject.InitiatedAction of
            ExchangeObject.InitiatedAction::InitiateSendToOCR:
                DisplayOCRUploadSuccessMessage(ExchangeObject.Count);

            ExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments:
                DisplayIncomingDocumentUploadSuccessMessage(ExchangeObject.Count);

            ExchangeObject.InitiatedAction::InitiateSendToAttachments:
                DisplayAttachmentUploadSuccessMessage(ExchangeObject.Count);
        end
    end;

    procedure GetContact(var Contact: Record Contact; LinkToNo: Code[20]): Boolean
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if IsAvailable() then begin
            GetContext(TempOfficeAddinContext);
            Contact.SetCurrentKey("E-Mail");
            Contact.SetRange("E-Mail", TempOfficeAddinContext.Email);
            if not Contact.IsEmpty() and (LinkToNo <> '') then begin
                ContactBusinessRelation.SetRange("No.", LinkToNo);
                if ContactBusinessRelation.FindSet() then
                    repeat
                        Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
                    until (ContactBusinessRelation.Next() = 0) or Contact.FindFirst();
            end;
            exit(Contact.FindFirst());
        end;
    end;

    procedure GetContext(var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.GetTempOfficeAddinContext(TempOfficeAddinContext);
    end;

    procedure GetEmailBody(OfficeAddinContext: Record "Office Add-in Context"): Text
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        if not OfficeAddinContext.IsAppointment() then
            exit(OfficeHostManagement.GetEmailBody(OfficeAddinContext));
    end;

    procedure GetFinancialsDocument() DocumentJSON: Text
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        GetContext(TempOfficeAddinContext);
        DocumentJSON := OfficeHostManagement.GetFinancialsDocument(TempOfficeAddinContext);
    end;

    procedure EmailHasAttachments(): Boolean
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        if OCRAvailable() then
            exit(OfficeHostManagement.EmailHasAttachments());
    end;

    local procedure GetRecRefFromVendorNo(VendorNumber: Code[20]): RecordRef
    var
        Vendor: Record Vendor;
        RecRef: RecordRef;
    begin
        Vendor.Validate("No.", VendorNumber);
        Vendor.Get(VendorNumber);
        RecRef.Get(Vendor.RecordId());
        exit(RecRef);
    end;

    procedure InitiateSendToOCR(VendorNumber: Code[20])
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.GetEmailAndAttachments(TempExchangeObject,
          TempExchangeObject.InitiatedAction::InitiateSendToOCR, GetRecRefFromVendorNo(VendorNumber));
        TempExchangeObject.SetRange(Type, TempExchangeObject.Type::Attachment);
        TempExchangeObject.SetFilter("Content Type", 'application/pdf|image/*');
        TempExchangeObject.SetRange(IsInline, false);
        if not TempExchangeObject.IsEmpty() then begin
            Session.LogMessage('0000AD0', StrSubstNo(IncomingDocumentTelemetryTxt, TempExchangeObject.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeAddinTelemetryCategoryTxt);
            Page.Run(Page::"Office OCR Incoming Documents", TempExchangeObject);
        end;
    end;

    procedure InitiateSendToIncomingDocumentsWithPurchaseHeaderLink(PurchaseHeader: Record "Purchase Header"; VendorNumber: Code[20])
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OfficeHostManagement: Codeunit "Office Host Management";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        OfficeOCRIncomingDocuments: Page "Office OCR Incoming Documents";
    begin
        OfficeHostManagement.GetEmailAndAttachments(TempExchangeObject,
          TempExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNumber));
        TempExchangeObject.SetRange(Type, TempExchangeObject.Type::Attachment);
        TempExchangeObject.SetRange(IsInline, false);
        if not TempExchangeObject.IsEmpty() then begin
            IncomingDocumentAttachment.Init();
            IncomingDocumentAttachment."Incoming Document Entry No." := PurchaseHeader."Incoming Document Entry No.";
            IncomingDocumentAttachment."Document Table No. Filter" := DATABASE::"Purchase Header";
            IncomingDocumentAttachment."Document Type Filter" := EnumAssignmentMgt.GetPurchIncomingDocumentType(PurchaseHeader."Document Type");
            IncomingDocumentAttachment."Document No. Filter" := PurchaseHeader."No.";
            OfficeOCRIncomingDocuments.InitializeIncomingDocumentAttachment(IncomingDocumentAttachment);
            OfficeOCRIncomingDocuments.InitializeExchangeObject(TempExchangeObject);
            OfficeOCRIncomingDocuments.Run();
        end;
    end;

    procedure InitiateSendToIncomingDocuments(VendorNumber: Code[20])
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.GetEmailAndAttachments(TempExchangeObject,
          TempExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNumber));
        TempExchangeObject.SetRange(Type, TempExchangeObject.Type::Attachment);
        TempExchangeObject.SetRange(IsInline, false);
        if not TempExchangeObject.IsEmpty() then
            Page.Run(Page::"Office OCR Incoming Documents", TempExchangeObject);
    end;

    procedure InitiateSendToAttachments(RecRef: RecordRef)
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.GetEmailAndAttachments(TempExchangeObject,
          TempExchangeObject.InitiatedAction::InitiateSendToAttachments, RecRef);
        TempExchangeObject.SetRange(Type, TempExchangeObject.Type::Attachment);
        TempExchangeObject.SetRange(IsInline, false);
        if not TempExchangeObject.IsEmpty() then
            if TempExchangeObject.Count = 1 then
                SendToAttachments(TempExchangeObject)
            else
                Page.RunModal(Page::"Office Attachments", TempExchangeObject);
    end;

    procedure InitiateSendApprovalRequest(VendorNumber: Code[20])
    var
        TempExchangeObject: Record "Exchange Object" temporary;
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.GetEmailAndAttachments(TempExchangeObject,
          TempExchangeObject.InitiatedAction::InitiateSendToWorkFlow, GetRecRefFromVendorNo(VendorNumber));
        TempExchangeObject.SetRange(Type, TempExchangeObject.Type::Attachment);
        TempExchangeObject.SetFilter("Content Type", 'application/pdf|image/*');
        TempExchangeObject.SetRange(IsInline, false);
        if not TempExchangeObject.IsEmpty() then
            Page.Run(Page::"Office OCR Incoming Documents", TempExchangeObject);
    end;

    procedure IsAvailable(): Boolean
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        exit(OfficeHostManagement.IsAvailable());
    end;

    procedure IsOutlookMobileApp(): Boolean
    begin
        if IsAvailable() then
            exit(GetHostType() = OfficeHostType.OutlookMobileApp());
    end;

    procedure IsPopOut(): Boolean
    begin
        if IsAvailable() then
            exit(GetHostType() = OfficeHostType.OutlookPopOut());
    end;

    procedure OCRAvailable(): Boolean
    begin
        if IsAvailable() then
            exit(not (GetHostType() in [OfficeHostType.OutlookPopOut(),
                                      OfficeHostType.OutlookMobileApp()]));
    end;

    procedure SelectAndChangeCompany() NewCompany: Text
    var
        SelectedCompany: Record Company;
        AccessibleCompanies: Page "Accessible Companies";
    begin
        AccessibleCompanies.Initialize();
        if SelectedCompany.Get(CompanyName()) then
            AccessibleCompanies.SetRecord(SelectedCompany);

        AccessibleCompanies.LookupMode(true);
        if AccessibleCompanies.RunModal() in [Action::LookupOK, Action::OK] then begin
            AccessibleCompanies.GetRecord(SelectedCompany);
            NewCompany := SelectedCompany.Name;
            ChangeCompany(NewCompany);
        end;
    end;

    [Scope('OnPrem')]
    procedure SendApprovalRequest(var IncomingDocument: Record "Incoming Document")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        IncomingDocument.TestReadyForApproval();
        if ApprovalsMgmt.CheckIncomingDocApprovalsWorkflowEnabled(IncomingDocument) then
            ApprovalsMgmt.OnSendIncomingDocForApproval(IncomingDocument);
    end;

    [Scope('OnPrem')]
    procedure SendToIncomingDocument(var TempExchangeObject: Record "Exchange Object" temporary; var IncomingDocument: Record "Incoming Document"; var IncomingDocAttachment: Record "Incoming Document Attachment"): Boolean
    var
        Vendor: Record Vendor;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        RecRef: RecordRef;
        InStream: InStream;
        OutStream: OutStream;
    begin
        if TempExchangeObject.Type = TempExchangeObject.Type::Attachment then begin
            TempExchangeObject.CalcFields(Content);
            TempExchangeObject.Content.CreateInStream(InStream);

            IncomingDocumentAttachment.Init();
            IncomingDocumentAttachment.Content.CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, TempExchangeObject.Name);
            IncomingDocumentAttachment.Validate("Document Table No. Filter", IncomingDocAttachment."Document Table No. Filter");
            IncomingDocumentAttachment.Validate("Document Type Filter", IncomingDocAttachment."Document Type Filter");
            IncomingDocumentAttachment.Validate("Document No. Filter", IncomingDocAttachment."Document No. Filter");
            IncomingDocumentAttachment.Modify();

            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, IncomingDocumentAttachment."Document No. Filter") then begin
                PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
                PurchaseHeader.Modify();
            end;

            IncomingDocument.SetRange("Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
            if TempExchangeObject.RecId.TableNo = DATABASE::Vendor then begin
                RecRef.Get(TempExchangeObject.RecId);
                RecRef.SetTable(Vendor);
                if IncomingDocument.FindFirst() then begin
                    Vendor.SetRange("No.", Vendor."No.");
                    if Vendor.FindFirst() then begin
                        IncomingDocument.Validate("Vendor Name", Vendor.Name);
                        IncomingDocument.Validate("Vendor No.", Vendor."No.");
                        IncomingDocument.Modify();
                        exit(true);
                    end;
                end;
            end;

            exit(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SendToAttachments(var TempExchangeObject: Record "Exchange Object" temporary): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        InStream: InStream;
    begin
        if TempExchangeObject.Type = TempExchangeObject.Type::Attachment then begin
            TempExchangeObject.CalcFields(Content);
            TempExchangeObject.Content.CreateInStream(InStream);
            DocumentAttachment.Init();
            RecRef.Get(TempExchangeObject.RecId);
            DocumentAttachment.SaveAttachmentFromStream(InStream, RecRef, TempExchangeObject.Name);
            exit(true);
        end;
        exit(false);
    end;

    procedure SendToOCR(var IncomingDocument: Record "Incoming Document")
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        OfficeHostManagement.SendToOCR(IncomingDocument);
    end;

    procedure StoreValue(Name: Text; Value: Text)
    begin
        InvokeExtension('storeValue', Name, Value, '', '');
    end;

    [Scope('OnPrem')]
    procedure GetOfficeAddinTelemetryCategory(): Text
    begin
        exit(OfficeAddinTelemetryCategoryTxt);
    end;

    procedure SaveEmailBodyHTML(OutputFileName: Text; HTMLText: Text)
    var
        OutStream: OutStream;
        OutputFile: File;
    begin
        OutputFile.WriteMode(true);
        OutputFile.Create(OutputFileName, TextEncoding::UTF8);
        OutputFile.CreateOutStream(OutStream);
        OutStream.Write(HTMLText, StrLen(HTMLText));
        OutputFile.Close();
    end;

    local procedure GetContent(ServerFilePath: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        DocStream: InStream;
    begin
        FileMgt.BLOBImportFromServerFile(TempBlob, ServerFilePath);
        TempBlob.CreateInStream(DocStream, TEXTENCODING::UTF8);

        exit(Base64Convert.ToBase64(DocStream));
    end;

    local procedure GetHandlerCodeunit(OfficeAddinContext: Record "Office Add-in Context"): Integer
    var
        OfficeJobsHandler: Codeunit "Office Jobs Handler";
        HostType: Text;
        ExternalHandler: Integer;
    begin
        if OfficeJobsHandler.IsJobsHostType(OfficeAddinContext) then
            exit(Codeunit::"Office Jobs Handler");

        HostType := GetHostType();

        OnGetExternalHandlerCodeunit(OfficeAddinContext, HostType, ExternalHandler);
        if ExternalHandler > 0 then
            exit(ExternalHandler);

        case HostType of
            OfficeHostType.OutlookItemRead(), OfficeHostType.OutlookItemEdit(), OfficeHostType.OutlookTaskPane(), OfficeHostType.OutlookMobileApp():
                exit(Codeunit::"Office Contact Handler");
            OfficeHostType.OutlookHyperlink():
                exit(Codeunit::"Office Document Handler");
        end;

        if ExternalHandler > 0 then
            exit(ExternalHandler);

        Error(CodeUnitNotFoundErr);
    end;

    local procedure GetHostName(): Text
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        exit(OfficeHostManagement.GetHostName());
    end;

    local procedure GetHostType(): Text
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        exit(OfficeHostManagement.GetHostType());
    end;

    local procedure InvokeExtension(FunctionName: Text; Parameter1: Variant; Parameter2: Variant; Parameter3: Variant; Parameter4: Variant)
    var
        OfficeHostManagement: Codeunit "Office Host Management";
    begin
        Session.LogMessage('0000ACV', StrSubstNo(ClientExtensionTelemetryTxt, FunctionName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeAddinTelemetryCategoryTxt);
        OfficeHostManagement.InvokeExtension(FunctionName, Parameter1, Parameter2, Parameter3, Parameter4);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteContact(var Rec: Record Contact; RunTrigger: Boolean)
    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
    begin
        // User has deleted the contact that was just created. Prevent user seeing a blank screen.
        if not IsAvailable() or Rec.IsTemporary() then
            exit;
        GetContext(TempOfficeAddinContext);
        if (Rec."E-Mail" = TempOfficeAddinContext.Email) and (Rec.Type = Rec.Type::Person) and (not Rec.Find()) then
            Page.Run(Page::"Office New Contact Dlg")
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetExternalHandlerCodeunit(OfficeAddinContext: Record "Office Add-in Context"; HostType: Text; var HandlerCodeunit: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'ChangeCompany', '', false, false)]
    local procedure OnChangeCompany(var NewCompanyName: Text)
    begin
        if not IsAvailable() then
            exit;

        NewCompanyName := SelectAndChangeCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", OnBeforeDownloadPdfAttachment, '', false, false)]
    local procedure OnBeforeDownloadPdfAttachment(var TempEmailItem: Record "Email Item" temporary)
    begin
        if not TempEmailItem.HasAttachments() or (not GuiAllowed()) or (this.IsAvailable() and not this.IsPopOut()) then
            Error(CannotSendMailThenDownloadErr);
    end;
}

