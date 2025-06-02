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
codeunit 3109 "PDF Helper Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ConvertPdfToImage(DocumentStream: InStream; var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer): Boolean
    var
        PdfConverterInstance: DotNet PdfConverter;
        PdfTargetDevice: DotNet PdfTargetDevice;
        MemoryStream: DotNet MemoryStream;
        ImageMemoryStream: DotNet MemoryStream;
        SharedDocumentStream: InStream;
    begin
        // Empty stream, no actions possible on the stream so return immediately
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
