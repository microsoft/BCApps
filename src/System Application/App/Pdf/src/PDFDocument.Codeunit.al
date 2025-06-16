
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
    procedure GetDocumentAttachmentStream(PdfStream: InStream; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(PDFDocumentImpl.GetDocumentAttachmentStream(PdfStream, TempBlob));
    end;

    /// <summary>
    /// Retrieves metadata properties from a PDF file, such as page size, author, title, and creation date.
    /// </summary>
    /// <param name="DocumentInStream">Input stream of the PDF file.</param>
    /// <returns>A JSON object containing the extracted PDF metadata.</returns>
    /// <remarks>
    /// The format of the returned JSON object looks like the following:
    /// {
    ///     "pageWidth": 210.0,
    ///     "pageHeight": 297.0,
    ///     "pagecount": 3,
    ///     "author": "Author Name",
    ///     "creationDate": "2025-06-04T10:00:00",
    ///     "creationTimeZone": "PT2H",
    ///     "creator": "PDF Generator",
    ///     "producer": "PDF Engine",
    ///     "subject": "Invoice Document",
    ///     "title": "Invoice #12345"
    /// }
    /// </remarks>
    procedure GetPdfProperties(DocumentInStream: InStream): JsonObject
    begin
        exit(PDFDocumentImpl.GetPdfProperties(DocumentInStream));
    end;

    /// <summary>
    /// Returns the number of pages in the provided PDF stream.
    /// </summary>
    /// <param name="DocumentInStream">Input stream of the PDF file.</param>
    /// <returns>The number of pages in the PDF document.</returns>
    procedure GetPdfPageCount(DocumentInStream: InStream): Integer
    begin
        exit(PDFDocumentImpl.GetPdfPageCount(DocumentInStream));
    end;

    /// <summary>
    /// Initiates a download of a ZIP archive containing all embedded attachments from the provided PDF stream.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    /// <remarks>
    /// This procedure does not return the ZIP archive directly. Instead, it triggers a download dialog for the user,
    /// allowing them to save the ZIP file locally. 
    /// </remarks>
    procedure GetZipArchive(PdfStream: InStream)
    begin
        PDFDocumentImpl.GetZipArchive(PdfStream);
    end;

    /// <summary>
    /// Retrieves the names of embedded file attachments from a PDF document.
    /// </summary>
    /// <param name="PdfStream">The input stream representing the PDF file to inspect.</param>
    /// <returns>
    ///  A list of strings containing the name of all embedded attachments found in the PDF.
    /// If no attachments are found, an empty list is returned.
    /// </returns>
    /// <remarks>
    /// This procedure is particularly useful for PDF/A-3 compliant documents that embed XML-based e-invoices,
    /// such as Factur-X, XRechnung, or ZUGFeRD formats. These formats typically include attachments like
    /// 'factur-x.xml', 'xrechnung.xml', or 'zugferd-invoice.xml' which are used for automated invoice processing.
    /// </remarks>
    procedure GetAttachmentNames(PdfStream: InStream): List of [Text]
    begin
        exit(PDFDocumentImpl.GetAttachmentNames(PdfStream));
    end;
}
