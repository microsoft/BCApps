// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.EServices.EDocument;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;
using System.Environment;
using System.Integration;

table 1173 "Document Attachment"
{
    Caption = 'Document Attachment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            Editable = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(4; "Attached Date"; DateTime)
        {
            Caption = 'Attached Date';
        }
        field(5; "File Name"; Text[250])
        {
            Caption = 'Attachment';
            NotBlank = true;

            trigger OnValidate()
            var
                DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
            begin
                if "File Name" = '' then
                    Error(EmptyFileNameErr);

                if DocumentAttachmentMgmt.IsDuplicateFile(
                    "Table ID", "No.", "Document Type", "Line No.", "File Name", "File Extension")
                then
                    Error(DuplicateErr);
            end;
        }
        field(6; "File Type"; Enum "Document Attachment File Type")
        {
            Caption = 'File Type';
        }
        field(7; "File Extension"; Text[30])
        {
            Caption = 'File Extension';

            trigger OnValidate()
            begin
                case LowerCase("File Extension") of
                    'jpg', 'jpeg', 'bmp', 'png', 'tiff', 'tif', 'gif':
                        "File Type" := "File Type"::Image;
                    'pdf':
                        "File Type" := "File Type"::PDF;
                    'docx', 'doc':
                        "File Type" := "File Type"::Word;
                    'xlsx', 'xls':
                        "File Type" := "File Type"::Excel;
                    'pptx', 'ppt':
                        "File Type" := "File Type"::PowerPoint;
                    'msg':
                        "File Type" := "File Type"::Email;
                    'xml':
                        "File Type" := "File Type"::XML;
                    else
                        "File Type" := "File Type"::Other;
                end;
            end;
        }
        field(8; "Document Reference ID"; Media)
        {
            Caption = 'Document Reference ID';
        }
        field(9; "Attached By"; Guid)
        {
            Caption = 'Attached By';
            Editable = false;
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));
        }
        field(10; User; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Attached By"),
                                                         "License Type" = const("Full User")));
            Caption = 'User';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Document Flow Purchase"; Boolean)
        {
            Caption = 'Flow to Purch. Trx';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentFlowPurchase(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not HasContent() then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(12; "Document Flow Sales"; Boolean)
        {
            Caption = 'Flow to Sales Trx';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentFlowSales(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not HasContent() then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(13; "Document Type"; Enum "Attachment Document Type")
        {
            Caption = 'Document Type';
        }
        field(14; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(15; "VAT Report Config. Code"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Config. Code';
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
        }
        field(20; "Document Flow Service"; Boolean)
        {
            Caption = 'Flow to Service Trx';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentFlowService(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not HasContent() then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(21; "Document Flow Production"; Boolean)
        {
            Caption = 'Flow to Production Trx';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not HasContent() then
                    Error(NoDocumentAttachedErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Document Type", "Line No.", ID)
        {
            Clustered = true;
        }
        key(Key2; "Document Reference ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", "File Name", "File Extension", "File Type")
        {
        }
    }

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        if IncomingFileName <> '' then begin
            Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
            Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));
        end;

        IsHandled := false;
        OnInsertOnBeforeCheckDocRefID(Rec, IsHandled);
        if not IsHandled then
            if not HasContent() then
                Error(NoDocumentAttachedErr);

        Validate("Attached Date", CurrentDateTime);
        if IsNullGuid("Attached By") then
            "Attached By" := UserSecurityId();
    end;

    var
        FileManagement: Codeunit "File Management";
        IncomingFileName: Text;
        NoDocumentAttachedErr: Label 'Please attach a document first.';
        EmptyFileNameErr: Label 'Please choose a file to attach.';
        NoContentErr: Label 'The selected file ''%1'' has no content. Please choose another file.', Comment = '%1=FileName';
        DuplicateErr: Label 'This file is already attached to the document. Please choose another file.';
        RecordRefNotFoundErr: Label 'The record reference is empty. Please save the record before attaching files.';

    procedure ImportAttachment(DocumentInStream: InStream; FileName: Text)
    begin
        ImportFromStream(DocumentInStream, FileName);
        if not HasContent() then
            Error(NoDocumentAttachedErr);

        Rec.Validate("Attached Date", CurrentDateTime);
        if IsNullGuid(Rec."Attached By") then
            Rec."Attached By" := UserSecurityId();

        Rec.Modify();
    end;

    procedure Export(ShowFileDialog: Boolean) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DocumentStream: OutStream;
        FullFileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExport(Rec, IsHandled, ShowFileDialog);
        if IsHandled then
            exit;

        if ID = 0 then
            exit;
        // Ensure document has value in DB
        if not HasContent() then
            exit;

        OnBeforeExportAttachment(Rec);
        FullFileName := "File Name" + '.' + "File Extension";
        TempBlob.CreateOutStream(DocumentStream);
        ExportToStream(DocumentStream);
        exit(FileManagement.BLOBExport(TempBlob, FullFileName, ShowFileDialog));
    end;

    procedure HasPostedDocumentAttachment("Record": Variant): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        RecRef.GetTable(Record);
        SetRange("Table ID", RecRef.Number);
        if IsPostedDocument(RecRef.Number) then begin
            FieldRef := RecRef.Field(3);
            RecNo := FieldRef.Value();
            SetRange("No.", RecNo);
            exit(not IsEmpty());
        end;

        exit(false);
    end;

    procedure SupportedByFileViewer(): Boolean
    begin
        case Rec."File Type" of
            Rec."File Type"::PDF:
                exit(true);
            Rec."File Type"::" ":
                begin
                    if Rec."File Extension" <> '' then
                        exit(LowerCase(Rec."File Extension") = 'pdf');

                    exit(Lowercase(Rec."File Name").EndsWith('pdf'))
                end;
            else
                exit(false);
        end;
    end;

    local procedure IsPostedDocument(TableID: Integer) Posted: Boolean
    begin
        if TableID in [Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header"] then
            exit(true);
        if TableID in [Database::"Purch. Inv. Header", Database::"Purch. Cr. Memo Hdr."] then
            exit(true);

        Posted := false;
        OnAfterIsPostedDocument(TableID, Posted);
        exit(Posted);
    end;

    procedure SaveAttachment(RecRef: RecordRef; FileName: Text; TempBlob: Codeunit "Temp Blob")
    begin
        SaveAttachment(RecRef, FileName, TempBlob, true);
    end;

    procedure SaveAttachment(RecRef: RecordRef; FileName: Text; TempBlob: Codeunit "Temp Blob"; AllowDuplicateFileName: Boolean)
    var
        DocStream: InStream;
    begin
        OnBeforeSaveAttachment(Rec, RecRef, FileName, TempBlob);

        if FileName = '' then
            Error(EmptyFileNameErr);
        // Validate file/media is not empty
        if not TempBlob.HasValue() then
            Error(NoContentErr, FileName);

        TempBlob.CreateInStream(DocStream);
        InsertAttachment(DocStream, RecRef, FileName, AllowDuplicateFileName);
    end;

    procedure SaveAttachment(Files: List of [FileUpload]; RecRef: RecordRef)
    begin
        // Default to MS-DOS encoding to keep consistent with existing behavior
        SaveAttachment(Files, RecRef, TextEncoding::MSDos);
    end;

    procedure SaveAttachment(Files: List of [FileUpload]; RecRef: RecordRef; EncodingType: TextEncoding)
    var
        CurrentFile: FileUpload;
        TempStream: InStream;
    begin
        foreach CurrentFile in Files do begin
            CurrentFile.CreateInStream(TempStream, EncodingType);
            Rec.Init();
            Rec.ID := 0;
            SaveAttachmentFromStream(TempStream, RecRef, CurrentFile.FileName, true);
        end;
    end;

    procedure SaveAttachmentFromStream(DocStream: InStream; RecRef: RecordRef; FileName: Text)
    begin
        SaveAttachmentFromStream(DocStream, RecRef, FileName, true);
    end;

    procedure SaveAttachmentFromStream(DocStream: InStream; RecRef: RecordRef; FileName: Text; AllowDuplicateFileName: Boolean)
    begin
        OnBeforeSaveAttachmentFromStream(Rec, RecRef, FileName, DocStream);

        if FileName = '' then
            Error(EmptyFileNameErr);

        InsertAttachment(DocStream, RecRef, FileName, AllowDuplicateFileName);
    end;

    local procedure InsertAttachment(DocStream: InStream; RecRef: RecordRef; FileName: Text; AllowDuplicateFileName: Boolean)
    var
        IsHandled: Boolean;
    begin
        if not RecRef.Find() then
            Error(RecordRefNotFoundErr);

        InitFieldsFromRecRef(RecRef);

        // If duplicate filename is allowed, use increment versions (specifically needed for phone Take/Use Photo functionality)
        if AllowDuplicateFileName then
            IncomingFileName := FindUniqueFileName(FileManagement.GetFileNameWithoutExtension(FileName), FileManagement.GetExtension(FileName))
        else
            IncomingFileName := FileName;

        Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
        Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));

        OnInsertAttachmentOnBeforeImportStream(Rec, DocStream, FileName, IsHandled);
        if not IsHandled then begin
            // IMPORTSTREAM(stream,description, mime-type,filename)
            // description and mime-type are set empty and will be automatically set by platform code from the filename
            ImportFromStream(DocStream, FileName);
            if not HasContent() then
                Error(NoDocumentAttachedErr);
        end;

        OnBeforeInsertAttachment(Rec, RecRef);
        Insert(true);
    end;

    procedure InitFieldsFromRecRef(RecRef: RecordRef)
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FieldRef: FieldRef;
        RecNo: Code[20];
        AttachmentDocumentType: Enum "Attachment Document Type";
        FieldNo: Integer;
        LineNo: Integer;
        VATRepConfigType: Enum "VAT Report Configuration";
    begin
        Validate("Table ID", RecRef.Number);

        if DocumentAttachmentMgmt.TableHasNumberFieldPrimayKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            RecNo := FieldRef.Value();
            Validate("No.", RecNo);
        end;

        if DocumentAttachmentMgmt.TableHasDocTypePrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            AttachmentDocumentType := FieldRef.Value();
            DocumentAttachmentMgmt.TransformAttachmentDocumentTypeValue(RecRef.Number(), AttachmentDocumentType);
            Validate("Document Type", AttachmentDocumentType);
        end;

        if DocumentAttachmentMgmt.TableHasLineNumberPrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            LineNo := FieldRef.Value();
            Validate("Line No.", LineNo);
        end;

        if DocumentAttachmentMgmt.TableHasVATReportConfigCodePrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            VATRepConfigType := FieldRef.Value();
            Validate("VAT Report Config. Code", VATRepConfigType);
        end;

        OnAfterInitFieldsFromRecRef(Rec, RecRef);
    end;

    procedure FindUniqueFileName(FileName: Text; FileExtension: Text): Text[250]
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FileIndex: Integer;
        SourceFileName: Text[250];
    begin
        SourceFileName := CopyStr(FileName, 1, MaxStrLen(SourceFileName));
        while DocumentAttachmentMgmt.IsDuplicateFile("Table ID", "No.", "Document Type", "Line No.", FileName, FileExtension) do begin
            FileIndex += 1;
            FileName := GetNextFileName(SourceFileName, FileIndex);
        end;
        exit(CopyStr(StrSubstNo('%1.%2', FileName, FileExtension), 1, MaxStrLen(SourceFileName)));
    end;

    procedure VATReturnSubmissionAttachmentsExist(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        DocType: Enum "Attachment Document Type";
    begin
        exit(VATReturnAttachmentsExist(VATReportHeader, DocType::"VAT Return Submission"));
    end;

    procedure VATReturnResponseAttachmentsExist(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        DocType: Enum "Attachment Document Type";
    begin
        exit(VATReturnAttachmentsExist(VATReportHeader, DocType::"VAT Return Response"));
    end;

    local procedure VATReturnAttachmentsExist(VATReportHeader: Record "VAT Report Header"; DocType: Enum "Attachment Document Type"): Boolean
    begin
        SetRange("Table ID", Database::"VAT Report Header");
        SetRange("No.", VATReportHeader."No.");
        SetRange("Document Type", DocType);
        exit(not IsEmpty());
    end;

    procedure DownloadZipFileWithVATReturnSubmissionAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]): Boolean
    begin
        exit(DownloadZipFileWithVATReturnAttachments(VATRepConfigCode, VATReportNo, "Document Type"::"VAT Return Submission"));
    end;

    procedure DownloadZipFileWithVATReturnResponseAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]): Boolean
    begin
        exit(DownloadZipFileWithVATReturnAttachments(VATRepConfigCode, VATReportNo, "Document Type"::"VAT Return Response"));
    end;

    local procedure DownloadZipFileWithVATReturnAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]; DocType: Enum "Attachment Document Type"): Boolean
    var
        VATReportHeader: Record "VAT Report Header";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
        ZipInStream: InStream;
        DocumentStream: OutStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        if not VATReportHeader.Get(VATRepConfigCode, VATReportNo) then
            exit(false);

        SetRange("Table ID", Database::"VAT Report Header");
        SetRange("No.", VATReportHeader."No.");
        SetRange("Document Type", DocType);
        if not FindSet() then
            exit(false);

        ToFile := VATReportHeader."No.";
        case "Document Type" of
            "Document Type"::"VAT Return Submission":
                ToFile += '_Submission.zip';
            "Document Type"::"VAT Return Response":
                ToFile += 'Response.zip';
        end;

        DataCompression.CreateZipArchive();
        repeat
            if HasContent() then begin
                Clear(TempBlob);
                TempBlob.CreateOutStream(DocumentStream);
                ExportToStream(DocumentStream);
                TempBlob.CreateInStream(ServerFileInStream);
                DataCompression.AddEntry(ServerFileInStream, "File Name" + '.' + "File Extension");
            end;
        until Next() = 0;
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        DownloadFromStream(ZipInStream, '', '', '', ToFile);
        exit(true);
    end;

    local procedure GetNextFileName(FileName: Text[250]; FileIndex: Integer): Text[250]
    begin
        exit(StrSubstNo('%1 (%2)', FileName, FileIndex));
    end;

    procedure HasContent() AttachmentHasContent: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeHasContent(Rec, AttachmentHasContent, IsHandled);
        if IsHandled then
            exit;

        AttachmentHasContent := "Document Reference ID".HasValue();
    end;

    procedure ImportFromStream(AttachmentInStream: InStream; FileName: Text)
    var
        IsHandled: Boolean;
    begin
        OnBeforeImportFromStream(Rec, AttachmentInStream, FileName, IsHandled);
        if IsHandled then
            exit;

        if AttachmentInStream.Length = 0 then
            Error(NoContentErr, FileName);

        Rec."Document Reference ID".ImportStream(AttachmentInStream, '', '', FileName);
    end;

    procedure ExportToStream(var AttachmentOutStream: OutStream)
    var
        IsHandled: Boolean;
    begin
        OnBeforeExportToStream(Rec, AttachmentOutStream, IsHandled);
        if IsHandled then
            exit;

        "Document Reference ID".ExportStream(AttachmentOutStream);
    end;

    procedure GetAsTempBlob(var TempBlob: Codeunit "Temp Blob")
    var
        TenantMedia: Record "Tenant Media";
        IsHandled: Boolean;
    begin
        OnBeforeGetAsTempBlob(Rec, TempBlob, IsHandled);
        if IsHandled then
            exit;

        TenantMedia.SetAutoCalcFields(Content);
        TenantMedia.Get(Rec."Document Reference ID".MediaId());
        TempBlob.FromRecord(TenantMedia, TenantMedia.FieldNo(Content));
    end;

    procedure GetContentType() ContentType: Text[100]
    var
        TenantMedia: Record "Tenant Media";
        IsHandled: Boolean;
    begin
        OnBeforeGetContentType(Rec, ContentType, IsHandled);
        if IsHandled then
            exit;

        TenantMedia.Get(Rec."Document Reference ID".MediaId());
        exit(TenantMedia."Mime Type");
    end;

    procedure ViewFile()
    var
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
    begin
        GetAsTempBlob(TempBlob);
        TempBlob.CreateInStream(FileInStream);
        File.ViewFromStream(FileInStream, Rec."File Name" + '.' + Rec."File Extension", true);
    end;

    procedure OpenInOneDrive(DocumentSharingIntent: Enum "Document Sharing Intent")
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        FileManagement: Codeunit "File Management";
        IsHandled: Boolean;
        FileName: Text;
        FileExtension: Text;
        FileExtensionLbl: Label '.%1', Locked = true;
    begin
        OnBeforeOpenInOneDrive(Rec, DocumentSharingIntent, IsHandled);
        if IsHandled then
            exit;

        FileName := FileManagement.StripNotsupportChrInFileName(Rec."File Name");
        FileExtension := StrSubstNo(FileExtensionLbl, Rec."File Extension");

        case DocumentSharingIntent of
            DocumentSharingIntent::Open:
                DocumentServiceMgt.OpenInOneDriveFromMedia(FileName, FileExtension, "Document Reference ID".MediaId());
            DocumentSharingIntent::Edit:
                if DocumentServiceMgt.EditInOneDriveFromMedia(FileName, FileExtension, "Document Reference ID".MediaId()) then begin
                    Rec."Attached Date" := CurrentDateTime();
                    Rec.Modify();
                end;
            DocumentSharingIntent::Share:
                DocumentServiceMgt.ShareWithOneDriveFromMedia(FileName, FileExtension, "Document Reference ID".MediaId())
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasContent(var DocumentAttachment: Record "Document Attachment"; var AttachmentIsAvailable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportFromStream(var DocumentAttachment: Record "Document Attachment"; var AttachmentInStream: InStream; var FileName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportToStream(var DocumentAttachment: Record "Document Attachment"; var AttachmentOutStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAsTempBlob(var DocumentAttachment: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenInOneDrive(var Rec: Record "Document Attachment"; DocumentSharingIntent: Enum "Document Sharing Intent"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetContentType(var Rec: Record "Document Attachment"; var ContentType: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean; ShowFileDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachment(var DocumentAttachment: Record "Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FileName: Text; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachmentFromStream(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FileName: Text; var DocStream: InStream)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentFlowPurchase(var DocumentAttachment: Record "Document Attachment"; xDocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentFlowSales(var DocumentAttachment: Record "Document Attachment"; xDocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentFlowService(var DocumentAttachment: Record "Document Attachment"; xDocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeCheckDocRefID(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAttachmentOnBeforeImportStream(var DocumentAttachment: Record "Document Attachment"; DocInStream: InStream; FileName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPostedDocument(TableID: Integer; var Posted: Boolean);
    begin
    end;
}

