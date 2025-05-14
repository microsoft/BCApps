// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;
using System.Utilities;

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
        OutputsImages: List of [OutStream];
    begin
        PdfConverter.PdfToImage(PdfInStream, OutputsImages, ImageFormat, DPI, Width, Height, PageNumber);
        OutputsImages.Get(1, ImageOutStream);
    end;

}