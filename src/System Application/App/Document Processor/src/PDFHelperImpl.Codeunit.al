// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;
using System.Utilities;
using System;
codeunit 3109 "PDF Helper Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        Init();
    end;

    var
        TempFolderPath: Text;
        Initialized: Boolean;
        ValidNamesTxt: Label 'factur-x.xml, xrechnung.xml, zugferd-invoice.xml', Locked = true;

    procedure Init()
    begin
        if Initialized then
            exit;

        TempFolderPath := GetOutputPath();

        Initialized := true;
    end;

    procedure GetOutputPath(): text
    begin
        exit(System.TemporaryPath);
    end;

    procedure SanitizeFilename(FileName: Text): Text
    begin
        FileName := FileName.Replace('/', '_');
        FileName := FileName.Replace('\', '_');
        exit(FileName);
    end;

    procedure GetInvoiceAttachmentStream(PdfStream: InStream; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        PdfAttachmentManager: DotNet PdfAttachmentManager;
        MemoryStream: DotNet MemoryStream;
        Name: Text;
        PdfAttachmentOutStream: OutStream;
        PdfAttachmentInStream: InStream;
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
            MemoryStream := PdfAttachmentManager.GetInvoiceAttachment('');
        end;

        if IsNull(MemoryStream) then
            exit(false);

        MemoryStream.Position := 0;
        MemoryStream.CopyTo(PdfAttachmentOutStream);
        exit(true);
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

    procedure ShowNames(PdfStream: InStream): Text
    var
        PdfAttachmentManager: DotNet PdfAttachmentManager;
        PdfAttachment: DotNet PdfAttachment;
        Names: Text;
        Name: Text;
    begin
        PdfAttachmentManager := PdfAttachmentManager.PdfAttachmentManager(PdfStream);

        foreach PdfAttachment in PdfAttachmentManager do begin
            Name := PdfAttachment.Name;
            if (Name = '') then
                continue;
            if Names <> '' then
                Names += ', ';
            Names += Name;
        end;
        exit(Names);
    end;

    procedure GetPdfProperties(DocumentStream: InStream): JsonObject
    var
        PdfDocumentInfoInstance: DotNet PdfDocumentInfo;
        PdfConverterInstance: DotNet PdfConverter;
        MemoryStream: DotNet MemoryStream;
        TextValue: text;
        IntegerValue: Integer;
        DecimalValue: Decimal;
        DateTimeValue: DateTime;
        DurationValue: Duration;
        JsonContainer: JsonObject;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        MemoryStream := DocumentStream;

        PdfConverterInstance := PdfConverterInstance.PdfConverter(MemoryStream);
        PdfDocumentInfoInstance := PdfConverterInstance.DocumentInfo();

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

    procedure ConvertPdfToImage(DocumentStream: InStream; var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer): Boolean
    var
        PdfConverterInstance: DotNet PdfConverter;
        PdfTargetDevice: DotNet PdfTargetDevice;
        MemoryStream: DotNet MemoryStream;
        ImageMemoryStream: DotNet MemoryStream;
        SharedDocumentStream: InStream;
    begin
        // Empty stream, no actions possible on the stream so return immediatly
        if DocumentStream.Length < 1 then
            exit(false);

        // Use a shared stream and reset the read pointer to beginning of stream.
        SharedDocumentStream := DocumentStream;
        if SharedDocumentStream.Position > 1 then
            SharedDocumentStream.ResetPosition();

        MemoryStream := MemoryStream.MemoryStream();
        MemoryStream := SharedDocumentStream;

        ConvertImageFormatToPdfTargetDevice(ImageFormat, PdfTargetDevice);
        ImageMemoryStream := PdfConverterInstance.ConvertPage(PdfTargetDevice, MemoryStream, PageNumber, 0, 0, 0); // apply default heighth, width and resolution
        // Copy data to the outgoing stream and make sure it is reset to the beginning of the stream.
        ImageMemoryStream.Seek(0, 0);
        ImageMemoryStream.CopyTo(ImageStream);
        ImageStream.Position(1);
        exit(true)
    end;

    local procedure ConvertImageFormatToPdfTargetDevice(ImageFormat: Enum "Image Format"; var PdfTargetDevice: DotNet PdfTargetDevice)
    begin
        case ImageFormat of
            ImageFormat::PNG:
                PdfTargetDevice := PdfTargetDevice.PngDevice;
            ImageFormat::JPEG:
                PdfTargetDevice := PdfTargetDevice.JpegDevice;
            ImageFormat::TIFF:
                PdfTargetDevice := PdfTargetDevice.TiffDevice;
            ImageFormat::BMP:
                PdfTargetDevice := PdfTargetDevice.BmpDevice;
            ImageFormat::GIF:
                PdfTargetDevice := PdfTargetDevice.GifDevice;
            else
                Error('Unsupported image format: %1', ImageFormat);
        end;
    end;
}
