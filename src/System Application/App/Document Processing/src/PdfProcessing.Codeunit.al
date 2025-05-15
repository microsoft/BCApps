// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;
using System.Utilities;

/// <summary>
/// This codeunit is used to process documents.
/// </summary>
codeunit 9564 "Pdf Processing"
{

    Access = Public;

    var
        /// <summary>
        /// This variable is used to store the document processing implementation.
        /// </summary>
        PdfProcessingImpl: Codeunit "Pdf Processing Impl";


    /// <summary>
    /// This procedure is used to convert a PDF file to an image.
    /// </summary>
    /// <param name="PdfInStream">Input stream of the PDF file.</param>
    /// <param name="ImageOutStream">Output stream of the image file.</param>
    /// <param name="ImageFormat">Image format to convert the PDF to.</param>
    /// <param name="DPI">Bitmap resolution in dots per inch.</param>
    /// <param name="Width">Width of the image in pixels.</param>
    /// <param name="Height">>Height of the image in pixels.</param>
    /// <param name="PageNumber">Page number to convert.</param>
    procedure ConvertPdfToImage(PdfInStream: InStream; ImageOutStream: OutStream; ImageFormat: Enum "Image Format"; DPI: Integer; Width: Integer; Height: Integer; PageNumber: Integer)
    begin
        PdfProcessingImpl.ConvertPdfToImage(PdfInStream, ImageOutStream, ImageFormat, DPI, Width, Height, PageNumber);
    end;


}