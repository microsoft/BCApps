
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;

/// <summary>
/// Codeunit that provides helper functions for PDF processing.
/// </summary>
codeunit 3110 "PDF Helper"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PDFHelperImpl: Codeunit "PDF Helper Impl";

    /// <summary>
    /// This procedure is used to convert a PDF file to an image.
    /// </summary>
    /// <param name="PdfInStream">Stream of the PDF file.</param>
    /// <param name="ImageStream">Stream of the image file.</param>
    /// <param name="ImageFormat">Image format to convert the PDF to.</param>
    /// <param name="PageNumber">Page number to convert.</param>
    procedure ConvertPdfToImage(PdfInStream: InStream; var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer)
    begin
        PDFHelperImpl.ConvertPdfToImage(PdfInStream, ImageStream, ImageFormat, PageNumber);
    end;
}
