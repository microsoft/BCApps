
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
    /// This procedure initializes the internal state of the object by resetting attachment lists
    /// and clearing user and admin codes, as well as any additional document names.
    /// </summary>
    procedure Initialize()
    begin
        PDFDocumentImpl.Initialize();
    end;
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
    /// <returns>Whether or not the conversion was successful.</returns>
    procedure ConvertPdfToImage(var ImageStream: InStream; ImageFormat: Enum "Image Format"; PageNumber: Integer): Boolean
    begin
        exit(PDFDocumentImpl.ConvertToImage(ImageStream, ImageFormat, PageNumber));
    end;

    /// <summary>
    /// This procedure is used to convert a PDF file to an image. Use ConvertPdfToImage to get a success flag.
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

    /// <summary>
    /// Configure the attachment lists. An empty name will reset the list. 
    /// This procedure adds a new attachment to the PDF document with the specified metadata and relationship type.
    /// </summary>
    /// <param name="AttachmentName">Attachment name. If empty, the list will be reset.</param>
    /// <param name="PDFAttachmentDataType">Defines the relationship of the attachment to the PDF (e.g. supplementary, source, data, alternative).</param>
    /// <param name="MimeType">MIME type of the attachment (e.g., application/pdf, image/png).</param>
    /// <param name="FileName">The file name of the attachment as it should appear in the PDF.</param>
    /// <param name="Description">A textual description of the attachment.</param>
    /// <param name="PrimaryDocument">Indicates whether this attachment is the primary document.</param>
    procedure AddAttachment(AttachmentName: Text; PDFAttachmentDataType: Enum "PDF Attach. Data Relationship"; MimeType: Text; FileName: Text; Description: Text; PrimaryDocument: Boolean)
    begin
        PDFDocumentImpl.AddAttachment(AttachmentName, PDFAttachmentDataType, MimeType, FileName, Description, PrimaryDocument);
    end;

    /// <summary>
    /// Configure the attachment lists. An empty name will reset the list.
    /// This procedure adds a new attachment to the PDF document with the specified metadata and relationship type.
    /// </summary>
    /// <param name="AttachmentName">Attachment name. If empty, the list will be reset.</param>
    /// <param name="PDFAttachmentDataType">Defines the relationship of the attachment to the PDF (e.g. supplementary, source, data, alternative).</param>
    /// <param name="MimeType">MIME type of the attachment (e.g., application/pdf, image/png).</param>
    /// <param name="FileInStream">The stream with content to attach in the PDF.</param>
    /// <param name="Description">A textual description of the attachment.</param>
    /// <param name="PrimaryDocument">Indicates whether this attachment is the primary document.</param>
    procedure AddAttachment(AttachmentName: Text; PDFAttachmentDataType: Enum "PDF Attach. Data Relationship"; MimeType: Text; FileInStream: InStream; Description: Text; PrimaryDocument: Boolean)
    begin
        PDFDocumentImpl.AddAttachment(AttachmentName, PDFAttachmentDataType, MimeType, FileInStream, Description, PrimaryDocument);
    end;

    /// <summary>
    /// Add a file to the list of files to append to the rendered document. Empty name will reset the list.
    /// </summary>
    /// <param name="FileName">Path to the file to append. Platform will remove the file when rendering has been completed.</param>
    [Scope('OnPrem')]
    procedure AddFileToAppend(FileName: Text)
    begin
        PDFDocumentImpl.AddFileToAppend(FileName);
    end;

    /// <summary>
    /// Add a stream to the list of files to append to the rendered document using a temporary file name.
    /// </summary>
    /// <param name="FileInStream">Stream with file content. Platform will remove the temporary file when rendering has been completed.</param>
    procedure AddStreamToAppend(FileInStream: InStream)
    begin
        PDFDocumentImpl.AddStreamToAppend(FileInStream);
    end;

    /// <summary>
    /// Protect the document with a user and admin code using text data type.
    /// </summary>
    /// <param name="User">User code.</param>
    /// <param name="Admin">Admin code.</param>
    [NonDebuggable]
    procedure ProtectDocument(User: Text; Admin: Text)
    begin
        PDFDocumentImpl.ProtectDocument(User, Admin);
    end;

    /// <summary>
    /// Protect the document with a user and admin code using secrettext data type.
    /// </summary>
    /// <param name="User">User code.</param>
    /// <param name="Admin">Admin code.</param>
    procedure ProtectDocument(User: SecretText; Admin: SecretText)
    begin
        PDFDocumentImpl.ProtectDocument(User, Admin);
    end;

    /// <summary>
    /// Returns the number of configured attachments. 
    /// Validates that all attachment-related lists (names, MIME types, data types, filenames, and descriptions) are synchronized in length.
    /// Throws an error if any of the lists are out of sync.
    /// </summary>
    /// <returns>The total number of attachments configured.</returns>

    procedure AttachmentCount(): Integer
    begin
        exit(PDFDocumentImpl.AttachmentCount());
    end;

    /// <summary>
    /// Returns the number of additional document names that have been appended.
    /// This count reflects how many supplementary documents are currently tracked.
    /// </summary>
    /// <returns>The total number of additional document names.</returns>
    procedure AppendedDocumentCount(): Integer
    begin
        exit(PDFDocumentImpl.AppendedDocumentCount());
    end;

    /// <summary>
    /// Converts the internal state of the PDF document configuration into a structured JSON payload.
    /// This includes metadata such as version, primary document, attachments, additional documents, and protection settings.
    /// </summary>
    /// <param name="RenderingPayload">The base JSON object to which the PDF configuration will be applied.</param>
    /// <returns>A JsonObject representing the complete rendering payload with all configured properties.</returns>
    /// <remarks>
    /// Throws an error if the payload already contains a primary document or protection block, as these cannot be overwritten.
    /// </remarks>

    [NonDebuggable]
    procedure ToJson(RenderingPayload: JsonObject): JsonObject
    begin
        exit(PDFDocumentImpl.ToJson(RenderingPayload));
    end;
}
