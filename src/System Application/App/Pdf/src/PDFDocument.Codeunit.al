
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

    /// <summary>
    /// This procedure is used to get the invoice attachment stream from a PDF file.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    /// <param name="TempBlob">Temporary blob to store the attachment.</param>
    procedure GetDocumentAttachmentStream(PdfStream: InStream; TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(PDFDocumentImpl.GetDocumentAttachmentStream(PdfStream, TempBlob));
    end;

    /// <summary>
    /// This procedure is used to get the properties of a PDF file.
    /// </summary>
    /// <param name="DocumentInStream">Input stream of the PDF file.</param>
    /// <returns>Properties of the PDF file in JSON format.</returns>
    procedure GetPdfProperties(DocumentInStream: InStream): JsonObject
    begin
        exit(PDFDocumentImpl.GetPdfProperties(DocumentInStream));
    end;

    /// <summary>
    /// Get the zip archive from the PDF stream.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    procedure GetZipArchive(PdfStream: InStream)
    begin
        PDFDocumentImpl.GetZipArchive(PdfStream);
    end;

    /// <summary>
    /// This procedure is used to get the names of the attachments in a PDF file.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    /// <returns>Names as comma-separated string.</returns>
    procedure ShowAttachmentNames(PdfStream: InStream): Text
    begin
        exit(PDFDocumentImpl.ShowAttachmentNames(PdfStream));
    end;

}
