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
}
