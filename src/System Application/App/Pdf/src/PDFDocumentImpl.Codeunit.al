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
        UnsupportedImageFormatErr: Label 'Unsupported image format: %1', Comment = '%1 is the image format that is not supported.';
        NotLoadedErr: Label 'PDF document is not loaded. Please load the document before performing this operation.';

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

    procedure GetDocumentAttachmentStream(PdfStream: InStream; TempBlob: Codeunit "Temp Blob"): Boolean
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
        ZipFilename: Text;
        ZipFileLbl: Label 'zip file';
    begin
        PdfAttachmentManager := PdfAttachmentManager.PdfAttachmentManager(PdfStream);
        AttachmentStream := PdfAttachmentManager.GetZipArchiveWithAttachments();

        ZipFilename := ZipFileLbl;
        DownloadFromStream(AttachmentStream, ZipFileLbl, '', '', ZipFilename);
    end;

    procedure GetAttachmentNames(PdfStream: InStream) AttachmentNames: List of [Text]
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
            AttachmentNames.Add(AttachmentName);
        end;

        exit(AttachmentNames);
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
}
