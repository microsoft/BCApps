// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;
using System;

/// <summary>
/// Codeunit that provides helper functions for PDF processing.
/// </summary>
codeunit 3109 "PDF Document Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DocumentStream: InStream;
        Loaded: Boolean;
        AttachmentNames: List of [Text];
        AttachmentDataTypes: List of [Enum "PDF Attach. Data Relationship"];
        AttachmentMimeTypes: List of [Text];
        AttachmentFileNames: List of [Text];
        AttachmentDescriptions: List of [Text];
        AdditionalDocumenNames: List of [Text];
        UserCode: SecretText;
        AdminCode: SecretText;
        PrimaryDocumentName: Text; // The primary document that will be used at the alternative representation of the PDF contents.
        SaveFormat: Enum "PDF Save Format";
        UnsupportedImageFormatErr: Label 'Unsupported image format: %1', Comment = '%1 = the image format that is not supported.';
        NotLoadedErr: Label 'PDF document is not loaded. Please load the document before performing this operation.';

    procedure Initialize()
    begin
        this.ResetAttachmentLists();
        Clear(this.AdditionalDocumenNames);
        Clear(this.UserCode);
        Clear(this.AdminCode);
    end;

    procedure Load(DocStream: InStream): Boolean
    begin
        // Empty stream, no actions possible on the stream so return immediately
        if DocStream.Length() < 1 then
            exit(false);

        DocumentStream := DocStream;
        Loaded := true;
        exit(true);
    end;

    procedure ConvertToImage(var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer): Boolean
    var
        PdfConverterInstance: DotNet PdfConverter;
        PdfTargetDevice: DotNet PdfTargetDevice;
        MemoryStream: DotNet MemoryStream;
        ImageMemoryStream: DotNet MemoryStream;
        SharedDocumentStream: InStream;
    begin
        // Check if the document is loaded
        if not Loaded then
            Error(NotLoadedErr);

        // Use a shared stream and reset the read pointer to beginning of stream.
        SharedDocumentStream := DocumentStream;
        if SharedDocumentStream.Position > 1 then
            SharedDocumentStream.ResetPosition();

        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, SharedDocumentStream);

        ConvertImageFormatToPdfTargetDevice(ImageFormat, PdfTargetDevice);
        ImageMemoryStream := PdfConverterInstance.ConvertPage(PdfTargetDevice, MemoryStream, PageNumber, 0, 0, 0); // apply default height, width and resolution
        // Copy data to the outgoing stream and make sure it is reset to the beginning of the stream.
        ImageMemoryStream.Seek(0, 0);
        ImageMemoryStream.CopyTo(ImageStream);
        ImageStream.Position(1);
        exit(true)
    end;

    local procedure ConvertImageFormatToPdfTargetDevice(ImageFormat: Enum "Image Format"; var PdfTargetDevice: DotNet PdfTargetDevice)
    begin
        case ImageFormat of
            ImageFormat::Png:
                PdfTargetDevice := PdfTargetDevice.PngDevice;
            ImageFormat::Jpeg:
                PdfTargetDevice := PdfTargetDevice.JpegDevice;
            ImageFormat::Tiff:
                PdfTargetDevice := PdfTargetDevice.TiffDevice;
            ImageFormat::Bmp:
                PdfTargetDevice := PdfTargetDevice.BmpDevice;
            ImageFormat::Gif:
                PdfTargetDevice := PdfTargetDevice.GifDevice;
            else
                Error(UnsupportedImageFormatErr, ImageFormat);
        end;
    end;

    procedure GetDocumentAttachmentStream(PdfStream: InStream; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        PdfAttachmentManager: DotNet PdfAttachmentManager;
        MemoryStream: DotNet MemoryStream;
        Name: Text;
        PdfAttachmentOutStream: OutStream;
        PdfAttachmentInStream: InStream;
        ValidNamesTxt: Label 'factur-x.xml, xrechnung.xml, zugferd-invoice.xml', Locked = true;
    begin
        TempBlob.CreateOutStream(PdfAttachmentOutStream);
        TempBlob.CreateInStream(PdfAttachmentInStream);

        PdfAttachmentManager := PdfAttachmentManager.PdfAttachmentManager(PdfStream);

        // Try to get the invoice attachment stored in the pdf xml metedata
        MemoryStream := PdfAttachmentManager.GetInvoiceAttachment('');

        if IsNull(MemoryStream) then begin
            // xmp did not register the attachment name, try to get the attachment by name
            // using a list of valid names from the E-Invoicing standard.
            Name := ValidNamesTxt;
            MemoryStream := PdfAttachmentManager.GetInvoiceAttachment(Name);
        end;

        if IsNull(MemoryStream) then
            exit(false);

        MemoryStream.Position := 0;
        MemoryStream.CopyTo(PdfAttachmentOutStream);
        exit(true);
    end;

    procedure GetPdfProperties(DocumentInStream: InStream): JsonObject
    var
        PdfDocumentInfoInstance: DotNet PdfDocumentInfo;
        TextValue: Text;
        IntegerValue: Integer;
        DecimalValue: Decimal;
        DateTimeValue: DateTime;
        DurationValue: Duration;
        JsonContainer: JsonObject;
    begin
        InitializePdfDocumentInfo(DocumentInStream, PdfDocumentInfoInstance);

        DecimalValue := PdfDocumentInfoInstance.PageWidth;
        JsonContainer.Add('pageWidth', DecimalValue);

        DecimalValue := PdfDocumentInfoInstance.PageHeight;
        JsonContainer.Add('pageHeight', DecimalValue);

        IntegerValue := PdfDocumentInfoInstance.PageCount;
        JsonContainer.Add('pagecount', IntegerValue);

        TextValue := PdfDocumentInfoInstance.Author;
        JsonContainer.Add('author', TextValue);

        DateTimeValue := PdfDocumentInfoInstance.CreationDate;
        JsonContainer.Add('creationDate', DateTimeValue);

        DurationValue := PdfDocumentInfoInstance.CreationTimeZone;
        JsonContainer.Add('creationTimeZone', DurationValue);

        TextValue := PdfDocumentInfoInstance.Creator;
        JsonContainer.Add('creator', TextValue);

        TextValue := PdfDocumentInfoInstance.Producer;
        JsonContainer.Add('producer', TextValue);

        TextValue := PdfDocumentInfoInstance.Subject;
        JsonContainer.Add('subject', TextValue);

        TextValue := PdfDocumentInfoInstance.Title;
        JsonContainer.Add('title', TextValue);
        exit(JsonContainer);
    end;

    procedure GetPdfPageCount(DocumentInStream: InStream): Integer
    var
        PdfDocumentInfoInstance: DotNet PdfDocumentInfo;
    begin
        InitializePdfDocumentInfo(DocumentInStream, PdfDocumentInfoInstance);
        exit(PdfDocumentInfoInstance.PageCount);
    end;

    procedure GetZipArchive(PdfStream: InStream)
    var
        PdfAttachmentManager: DotNet PdfAttachmentManager;
        AttachmentStream: InStream;
        ZipFileName: Text;
        ZipFileLbl: Label 'zip file';
    begin
        PdfAttachmentManager := PdfAttachmentManager.PdfAttachmentManager(PdfStream);
        AttachmentStream := PdfAttachmentManager.GetZipArchiveWithAttachments();

        ZipFileName := ZipFileLbl;
        DownloadFromStream(AttachmentStream, ZipFileLbl, '', '', ZipFileName);
    end;

    procedure GetAttachmentNames(PdfStream: InStream) AttachmentNameList: List of [Text]
    var
        PdfAttachmentManager: DotNet PdfAttachmentManager;
        PdfAttachment: DotNet PdfAttachment;
        AttachmentName: Text;
    begin
        PdfAttachmentManager := PdfAttachmentManager.PdfAttachmentManager(PdfStream);

        foreach PdfAttachment in PdfAttachmentManager do begin
            AttachmentName := PdfAttachment.Name;
            if AttachmentName = '' then
                continue;
            AttachmentNameList.Add(AttachmentName);
        end;

        exit(AttachmentNameList);
    end;

    local procedure InitializePdfDocumentInfo(DocumentInStream: InStream; var PdfDocumentInfoInstance: DotNet PdfDocumentInfo)
    var
        PdfConverterInstance: DotNet PdfConverter;
        MemoryStream: DotNet MemoryStream;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        MemoryStream := DocumentInStream;

        PdfConverterInstance := PdfConverterInstance.PdfConverter(MemoryStream);
        PdfDocumentInfoInstance := PdfConverterInstance.DocumentInfo();
    end;

    procedure AddAttachment(AttachmentName: Text; PDFAttachmentDataType: Enum "PDF Attach. Data Relationship"; MimeType: Text; FileInStream: InStream; Description: Text; PrimaryDocument: Boolean)
    var
        TempFileName: Text;
    begin
        if FileInStream.Length = 0 then
            exit;
        TempFileName := this.CreateDataFileFromStream(FileInStream);
        this.AddAttachment(AttachmentName, PDFAttachmentDataType, MimeType, TempFileName, Description, PrimaryDocument);
    end;

    [Scope('OnPrem')]
    procedure AddAttachment(AttachmentName: Text; PDFAttachmentDataType: Enum "PDF Attach. Data Relationship"; MimeType: Text; FileName: Text; Description: Text; PrimaryDocument: Boolean)
    var
        AttachmentNameErr: Label 'Attachment with name %1 already exists.', Comment = '%1 = attachment name';
    begin
        if AttachmentName = '' then begin
            ResetAttachmentLists();
            exit;
        end;

        if this.AttachmentNames.Contains(AttachmentName) then
            Error(AttachmentNameErr, AttachmentName);

        this.AttachmentNames.Add(AttachmentName);
        this.AttachmentDataTypes.Add(PDFAttachmentDataType);
        this.AttachmentMimeTypes.Add(MimeType);
        this.AttachmentFileNames.Add(FileName);
        this.Attachmentdescriptions.Add(Description);
        if PrimaryDocument then begin
            this.PrimaryDocumentName := AttachmentName;
            this.SaveFormat := "PDF Save Format"::Einvoice;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddFileToAppend(FileName: Text)
    begin
        if FileName = '' then begin
            if this.AppendedDocumentCount() > 0 then
                Clear(this.AdditionalDocumenNames);
            exit;
        end;

        this.AdditionalDocumenNames.Add(FileName);
    end;

    procedure AddStreamToAppend(FileInStream: InStream)
    var
        TempFileName: Text;
    begin
        TempFileName := this.CreateDataFileFromStream(FileInStream);
        this.AddFileToAppend(TempFileName);
    end;

    local procedure CreateDataFileFromStream(FileInStream: InStream) FileName: Text
    var
        TempFile: File;
        LocalInStream: InStream;
        FileOutStream: OutStream;
    begin
        if FileInStream.Length = 0 then
            exit('');
        LocalInStream := FileInStream;
        LocalInStream.ResetPosition();
        TempFile.CreateTempFile();
        FileName := TempFile.Name;
        TempFile.Close();
        TempFile.Create(FileName);
        TempFile.CreateOutStream(FileOutStream);

        CopyStream(FileOutStream, LocalInStream);
        TempFile.Close();
        exit(FileName);
    end;

    [NonDebuggable]
    procedure ProtectDocument(User: Text; Admin: Text)
    begin
        UserCode := User;
        AdminCode := Admin;
    end;

    [NonDebuggable]
    procedure ProtectDocument(User: SecretText; Admin: SecretText)
    begin
        UserCode := User;
        AdminCode := Admin;
    end;

    procedure AttachmentCount(): Integer
    var
        AttachmentNamesCount: Integer;
        AttachmentErr: Label 'Attachment information lists are not in sync.';
    begin
        AttachmentNamesCount := AttachmentNames.Count();

        if (AttachmentNamesCount <> AttachmentMimeTypes.Count()) or
        (AttachmentNamesCount <> AttachmentDataTypes.Count()) or
        (AttachmentNamesCount <> AttachmentFileNames.Count()) or
        (AttachmentNamesCount <> AttachmentDescriptions.Count()) then
            Error(AttachmentErr);

        exit(AttachmentNamesCount);
    end;

    procedure AppendedDocumentCount(): Integer
    begin
        exit(AdditionalDocumenNames.Count());
    end;

    local procedure ResetAttachmentLists()
    begin
        Clear(this.AttachmentNames);
        Clear(this.AttachmentMimeTypes);
        Clear(this.AttachmentFileNames);
        Clear(this.AttachmentDataTypes);
        Clear(this.AttachmentDescriptions);
        Clear(this.PrimaryDocumentName);
        Clear(this.SaveFormat);
    end;

    procedure ToJson(RenderingPayload: JsonObject): JsonObject
    var
        JsonElement: JsonObject;
        Json: JsonObject;
        JsonDataArray: JsonArray;
        User, Admin : SecretText;
        VersionTokenLbl: Label 'version', Locked = true;
        JsonVersionTxt: Label '1.0', Locked = true;
    begin
        Json := RenderingPayload;
        if not Json.Contains(VersionTokenLbl) then
            Json.Add(VersionTokenLbl, JsonVersionTxt);

        AddPrimaryDocument(Json);
        SetJsonTokens(JsonElement, JsonDataArray);
        AddAttachments(Json, JsonDataArray);
        SetDocumentProtection(Json, User, Admin, JsonElement);

        exit(Json);
    end;

    local procedure AddPrimaryDocument(var Json: JsonObject)
    var
        JsonTextToken: JsonToken;
        TextVar: Text;
        PrimaryDocumentTokenLbl: Label 'primaryDocument', Locked = true;
        SaveFormatTokenLbl: Label 'saveformat', Locked = true;
        PrimaryDocumentOverrideErr: Label 'The rendering payload already contains a primary document. This cannot be overwritten.';
    begin
        if StrLen(this.PrimaryDocumentName) = 0 then
            exit;

        if Json.Contains(PrimaryDocumentTokenLbl) then begin
            Json.Get(PrimaryDocumentTokenLbl, JsonTextToken);
            if JsonTextToken.WriteTo(TextVar) then
                // The rendering payload already contains a primary document. This cannot be overwritten. Fail with an error.
                if TextVar <> '' then
                    Error(PrimaryDocumentOverrideErr);

            Json.Replace(PrimaryDocumentTokenLbl, this.PrimaryDocumentName);
        end else
            Json.Add(PrimaryDocumentTokenLbl, this.PrimaryDocumentName);

        if Json.Contains(SaveFormatTokenLbl) then
            Json.Replace(SaveFormatTokenLbl, Format(this.SaveFormat, 0, 2))
        else
            Json.Add(SaveFormatTokenLbl, Format(this.SaveFormat, 0, 2));
    end;

    local procedure SetJsonTokens(var JsonElement: JsonObject; var JsonDataArray: JsonArray)
    var
        i: Integer;
        DataType: Enum "PDF Attach. Data Relationship";
        Name: Text;
        MimeType: Text;
        FileName: Text;
        Description: Text;
        NameTokenLbl: Label 'name', Locked = true;
        RelationshipTokenLbl: Label 'relationship', Locked = true;
        MimeTypeTokenLbl: Label 'mimetype', Locked = true;
        FileNameTokenLbl: Label 'filename', Locked = true;
        DescriptionTokenLbl: Label 'description', Locked = true;
    begin
        for i := 1 to this.AttachmentCount() do begin
            this.FetchAttachment(i, name, DataType, MimeType, FileName, Description);
            clear(JsonElement);
            JsonElement.Add(NameTokenLbl, name);
            JsonElement.Add(DescriptionTokenLbl, Description);
            JsonElement.Add(RelationshipTokenLbl, Format(DataType, 0, 2));
            JsonElement.Add(MimeTypeTokenLbl, MimeType);
            JsonElement.Add(FileNameTokenLbl, FileName);
            JsonDataArray.Add(JsonElement);
        end;
    end;

    local procedure AddAttachments(var Json: JsonObject; var JsonDataArray: JsonArray)
    var
        i: Integer;
        SourceDataArray: JsonArray;
        JsonTokenElement: JsonToken;
        AttachmentsTokenLbl: Label 'attachments', Locked = true;
        AdditionalDocumentsTokenLbl: Label 'additionalDocuments', Locked = true;
    begin
        if (Json.Contains(AttachmentsTokenLbl)) then begin
            // The rendering payload already contains attachments. We need to add the new ones to the existing list.
            SourceDataArray := Json.GetArray(AttachmentsTokenLbl);

            for i := 0 to JsonDataArray.Count() - 1 do begin
                JsonDataArray.Get(i, JsonTokenElement);
                SourceDataArray.Add(JsonTokenElement);
            end;
            Json.Replace(AttachmentsTokenLbl, SourceDataArray);
        end else
            Json.Add(AttachmentsTokenLbl, JsonDataArray);

        Clear(JsonDataArray);
        Clear(SourceDataArray);

        if (Json.Contains(AdditionalDocumentsTokenLbl)) then begin
            SourceDataArray := Json.GetArray(AdditionalDocumentsTokenLbl);
            for i := 1 to this.AppendedDocumentCount() do
                SourceDataArray.Add(this.AdditionalDocumenNames.Get(i));
            Json.Replace(AdditionalDocumentsTokenLbl, SourceDataArray);
        end else begin
            for i := 1 to this.AppendedDocumentCount() do
                JsonDataArray.Add(this.AdditionalDocumenNames.Get(i));
            Json.Add(AdditionalDocumentsTokenLbl, JsonDataArray);
        end;
    end;

    [NonDebuggable]
    local procedure SetDocumentProtection(var Json: JsonObject; var User: SecretText; var Admin: SecretText; var JsonElement: JsonObject)
    var
        HasProtection: Boolean;
        ProtectionOverrideErr: Label 'The rendering payload already contains protection. This cannot be overwritten.';
        ProtectionTokenLbl: Label 'protection', Locked = true;
        UserTokenLbl: Label 'user', Locked = true;
        AdminTokenLbl: Label 'admin', Locked = true;
    begin
        HasProtection := this.FetchDocumentProtection(User, Admin);
        if (Json.Contains(ProtectionTokenLbl)) then begin
            // The rendering payload already contains protection. This cannot be overwritten. Fail with an error. 
            if (HasProtection) then
                Error(ProtectionOverrideErr);
        end else begin
            Clear(JsonElement);
            JsonElement.Add(UserTokenLbl, User.Unwrap());
            JsonElement.Add(AdminTokenLbl, Admin.Unwrap());
            Json.Add(ProtectionTokenLbl, JsonElement);
        end;
    end;

    [NonDebuggable]
    local procedure FetchDocumentProtection(var User: SecretText; var Admin: SecretText) HasProtection: Boolean
    begin
        User := UserCode;
        Admin := AdminCode;
        HasProtection := not (User.IsEmpty() and Admin.IsEmpty());
    end;

    local procedure FetchAttachment(AttachmentIndex: Integer; var AttachmentName: Text; var DataType: Enum "PDF Attach. Data Relationship"; var MimeType: Text; var FileName: Text; var AttachmentDescription: Text): Boolean
    var
        AttachmentIndexErr: Label 'Attachment index must be greater than 0.';
        AttachmentRangeErr: Label 'Attachment index is out of range.';
    begin
        if (AttachmentIndex < 1) then
            Error(AttachmentIndexErr);

        if (AttachmentIndex > this.AttachmentCount()) then
            Error(AttachmentRangeErr);

        AttachmentName := this.AttachmentNames.Get(AttachmentIndex);
        DataType := this.AttachmentDataTypes.Get(AttachmentIndex);
        MimeType := this.AttachmentMimeTypes.Get(AttachmentIndex);
        FileName := this.AttachmentFileNames.Get(AttachmentIndex);
        AttachmentDescription := this.AttachmentDescriptions.Get(AttachmentIndex);
        if not File.Exists(FileName) then
            exit(false);

        exit(true);
    end;
}
