// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Attachment Provider"
{
    /// <summary>
    /// Generates a PDF attachment as an additional document reference from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="AdditionalDocumentReferenceID">Returns the additional document reference ID.</param>
    /// <param name="AdditionalDocRefDocumentType">Returns the additional document reference document type.</param>
    /// <param name="URI">Returns the document URI.</param>
    /// <param name="Filename">Returns the PDF filename.</param>
    /// <param name="MimeCode">Returns the PDF MIME code.</param>
    /// <param name="EmbeddedDocumentBinaryObject">Returns the embedded PDF binary object.</param>
    procedure GeneratePDFAttachmentAsAdditionalDocRef(PurchaseHeader: Record "Purchase Header"; var AdditionalDocumentReferenceID: Text; var AdditionalDocRefDocumentType: Text; var URI: Text; var Filename: Text; var MimeCode: Text; var EmbeddedDocumentBinaryObject: Text)
}
