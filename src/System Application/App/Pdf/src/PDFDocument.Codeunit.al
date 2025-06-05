
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;

/// <summary>
/// Codeunit that provides helper functions for PDF processing.
/// </summary>
codeunit 3110 "PDF Document"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PDFDocumentImpl: Codeunit "PDF Document Impl.";

    /// <summary>
    /// This procedure is used to load a PDF document from a stream.
    /// </summary>
    /// <param name="DocumentStream">Stream of the PDF document.</param>
    /// <returns>Returns true if the document is loaded successfully, otherwise false.</returns>
    procedure Load(DocumentStream: InStream): Boolean
    begin
        exit(PDFDocumentImpl.Load(DocumentStream));
    end;

    /// <summary>
    /// This procedure is used to convert a PDF file to an image.
    /// </summary>
    /// <param name="ImageStream">Stream of the image file.</param>
    /// <param name="ImageFormat">Image format to convert the PDF to.</param>
    /// <param name="PageNumber">Page number to convert.</param>
    procedure ConvertToImage(var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer)
    begin
        PDFDocumentImpl.ConvertToImage(ImageStream, ImageFormat, PageNumber);
    end;
}
