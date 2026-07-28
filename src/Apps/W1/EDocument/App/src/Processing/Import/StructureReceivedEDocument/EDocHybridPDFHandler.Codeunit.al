// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.IO;
using System.Utilities;

/// <summary>
/// Structures hybrid PDF e-invoices (PDF/A-3 containers that embed the invoice as XML, such as
/// ZUGFeRD and Factur-X) by lifting the embedded XML out of the PDF instead of extracting the data
/// from the rendered page. PDFs without an embedded e-invoice are handed over to the MLLM handler,
/// which is the behavior for plain PDFs.
/// </summary>
codeunit 6431 "E-Doc. Hybrid PDF Handler" implements IStructureReceivedEDocument, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StructuredData: Text;
        EmbeddedInvoiceFoundMsg: Label 'Hybrid PDF: embedded e-invoice XML extracted from the PDF/A-3 container.', Locked = true;
        NoEmbeddedInvoiceMsg: Label 'Hybrid PDF: no embedded e-invoice XML found, falling back to MLLM extraction.', Locked = true;

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        EDocumentMLLMHandler: Codeunit "E-Document MLLM Handler";
        SourceBlob: Codeunit "Temp Blob";
        PdfInStream: InStream;
    begin
        SourceBlob := EDocumentDataStorage.GetTempBlob();
        SourceBlob.CreateInStream(PdfInStream);

        if TryExtractEmbeddedEInvoice(PdfInStream) and (StructuredData <> '') then begin
            Session.LogMessage('0000SXA', EmbeddedInvoiceFoundMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
            exit(this);
        end;

        Session.LogMessage('0000SXB', NoEmbeddedInvoiceMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
        exit(EDocumentMLLMHandler.StructureReceivedEDocument(EDocumentDataStorage));
    end;

    procedure GetFileFormat(): Enum "E-Doc. File Format"
    begin
        exit("E-Doc. File Format"::XML);
    end;

    procedure GetContent(): Text
    begin
        exit(StructuredData);
    end;

    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        // The embedded document can be expressed in different syntaxes and profiles (ZUGFeRD, Factur-X, ...),
        // so the reader configured on the E-Document or on the E-Document service decides how to read it.
        exit("E-Doc. Read into Draft"::Unspecified);
    end;

    [TryFunction]
    local procedure TryExtractEmbeddedEInvoice(PdfInStream: InStream)
    var
        PDFDocument: Codeunit "PDF Document";
        EmbeddedBlob: Codeunit "Temp Blob";
        EmbeddedXml: XmlDocument;
        RootElement: XmlElement;
        NoEmbeddedEInvoiceErr: Label 'The PDF does not contain an embedded e-invoice.', Locked = true;
    begin
        Clear(StructuredData);
        if not PDFDocument.GetDocumentAttachmentStream(PdfInStream, EmbeddedBlob) then
            Error(NoEmbeddedEInvoiceErr);

        if not XmlDocument.ReadFrom(EmbeddedBlob.CreateInStream(TextEncoding::UTF8), EmbeddedXml) then
            Error(NoEmbeddedEInvoiceErr);

        EmbeddedXml.GetRoot(RootElement);
        if not IsEInvoiceRootElement(RootElement.LocalName()) then
            Error(NoEmbeddedEInvoiceErr);

        EmbeddedXml.WriteTo(StructuredData);
    end;

    local procedure IsEInvoiceRootElement(LocalName: Text): Boolean
    begin
        // CII (ZUGFeRD, Factur-X) and UBL (PEPPOL) are the syntaxes used by hybrid PDF e-invoices
        case UpperCase(LocalName) of
            'CROSSINDUSTRYINVOICE',
            'INVOICE',
            'CREDITNOTE':
                exit(true);
        end;

        exit(false);
    end;
}
