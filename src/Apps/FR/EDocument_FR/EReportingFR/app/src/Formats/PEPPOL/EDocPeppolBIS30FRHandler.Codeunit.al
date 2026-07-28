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
/// Reads Peppol BIS 3.0 FR documents into the v2 import draft staging tables.
/// Peppol BIS 3.0 FR is standard UBL, so the parsing is delegated to the core PEPPOL reader. The
/// French specific elements that the export injects (Sales Order, Bill-to Customer and Ship-to
/// party references) are carried by standard UBL elements that the core reader already maps.
/// </summary>
codeunit 10985 "E-Doc. Peppol BIS 3.0 FR Hdlr" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Reads a Peppol BIS 3.0 FR XML document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the XML document stream to be processed.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPEPPOLHandler: Codeunit "E-Document PEPPOL Handler";
    begin
        exit(EDocumentPEPPOLHandler.ReadIntoDraft(EDocument, TempBlob));
    end;

    /// <summary>
    /// Displays a readable view of the purchase information that was extracted from the document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document to be displayed.</param>
    /// <param name="TempBlob">A temporary blob containing the document data.</param>
    internal procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        EDocumentPEPPOLHandler: Codeunit "E-Document PEPPOL Handler";
    begin
        EDocumentPEPPOLHandler.View(EDocument, TempBlob);
    end;
}
