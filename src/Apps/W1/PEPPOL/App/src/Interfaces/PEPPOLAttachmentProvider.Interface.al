// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;

/// <summary>
/// Interface for handling document attachments in PEPPOL electronic documents.
/// Provides methods for processing document attachments, generating additional document references,
/// and creating PDF attachments for inclusion in PEPPOL XML documents according to UBL standards.
/// </summary>
interface "PEPPOL Attachment Provider"
{
    /// <summary>
    /// Gets additional document reference information from document attachments.
    /// </summary>
    /// <param name="AttachmentNumber">The attachment number to process.</param>
    /// <param name="DocumentAttachments">The document attachments record.</param>
    /// <param name="Salesheader">The sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Return value: Additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Return value: Additional document reference document type.</param>
    /// <param name="URI">Return value: URI for the attachment.</param>
    /// <param name="Filename">Return value: Attachment filename.</param>
    /// <param name="MimeCode">Return value: MIME code for the attachment.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Return value: Base64 encoded attachment content.</param>
    /// <param name="NewProcessedDocType">The document type being processed (Sale or Service).</param>
    procedure GetAdditionalDocRefInfo(AttachmentNumber: Integer; var DocumentAttachments: Record "Document Attachment"; Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)

    /// <summary>
    /// Gets additional document reference information without specific attachment processing.
    /// </summary>
    /// <param name="Salesheader">The sales header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Return value: Additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Return value: Additional document reference document type.</param>
    /// <param name="URI">Return value: URI for the attachment.</param>
    /// <param name="MimeCode">Return value: MIME code for the attachment.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Return value: Base64 encoded attachment content.</param>
    /// <param name="NewProcessedDocType">The document type being processed (Sale or Service).</param>
    procedure GetAdditionalDocRefInfo(Salesheader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text; NewProcessedDocType: Option Sale,Service)

    /// <summary>
    /// Generates a PDF attachment from report set in Report Selections.
    /// </summary>
    /// <param name="SalesHeader">Record "Sales Header" that contains the document information.</param>
    /// <param name="AdditionalDocumentReferenceID">Additional Document Reference ID is set to original document no.</param>
    /// <param name="AdditionalDocRefDocumentType">Document type is set to an empty string.</param>
    /// <param name="URI">URI is set to an empty string.</param>
    /// <param name="Filename">Filename generated in format 'DocumentType_DocumentNo.pdf'.</param>
    /// <param name="MimeCode">The MimeCode is set to application/pdf.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Text output parameter that contains the Base64 encoded PDF content.</param>
    procedure GeneratePDFAttachmentAsAdditionalDocRef(SalesHeader: Record "Sales Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
}