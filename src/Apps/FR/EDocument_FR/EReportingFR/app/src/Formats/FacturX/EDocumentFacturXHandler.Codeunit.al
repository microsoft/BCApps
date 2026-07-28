// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

/// <summary>
/// Reads Factur-X FR documents into the v2 import draft staging tables.
/// Factur-X is a PDF/A-3 container that embeds the invoice as UN/CEFACT Cross Industry Invoice (CII)
/// XML, so the parsing is delegated to the shared CII reader. The blob can be either the PDF/A-3
/// container or the plain CII XML, depending on how the document was received.
/// </summary>
codeunit 10986 "E-Document Factur-X Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Reads a Factur-X document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the Factur-X PDF/A-3 file or its CII XML.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentCIIHandler: Codeunit "E-Document CII Handler";
    begin
        exit(EDocumentCIIHandler.ReadIntoDraft(EDocument, TempBlob));
    end;

    /// <summary>
    /// Displays a readable view of the purchase information that was extracted from the document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document to be displayed.</param>
    /// <param name="TempBlob">A temporary blob containing the document data.</param>
    internal procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        EDocumentCIIHandler: Codeunit "E-Document CII Handler";
    begin
        EDocumentCIIHandler.View(EDocument, TempBlob);
    end;
}
