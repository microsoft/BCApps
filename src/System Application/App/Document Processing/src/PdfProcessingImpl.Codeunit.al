// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System.Utilities;
using System;

/// <summary>
/// This codeunit is used to process documents.
/// </summary>
codeunit 9563 "Pdf Processing Impl"
{

    Access = Internal;

    /// <summary>
    /// Converts a PDF file to an image.
    /// </summary>
    procedure ConvertPdfToImage(PdfInStream: InStream; ImageOutStream: OutStream; ImageFormat: Enum "Image Format"; DPI: Integer; Width: Integer; Height: Integer; PageNumber: Integer)
    var
        PdfConverter: DotNet PdfConverter;
        PdfTargetDevice: DotNet PdfTargetDevice;
        MemoryStream: DotNet MemoryStream;
        GenericList: DotNet GenericList1;
    begin
        ConvertImageFormatToPdfTargetDevice(ImageFormat, PdfTargetDevice);
        PdfConverter.ConvertPdfToImage(PdfInStream, GenericList, DPI, PdfTargetDevice, PageNumber, 1, Width, Height);
        // Get the first image from the list
        MemoryStream := GenericList.ToArray().GetValue(0);
        MemoryStream.WriteTo(ImageOutStream);
        MemoryStream.Close();
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