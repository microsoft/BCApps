// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

/// <summary>
/// Reads PEPPOL BIS 3.0 DE documents into the v2 import draft staging tables.
/// PEPPOL BIS 3.0 DE and XRechnung are both UBL specifications of PEPPOL BIS Billing 3.0, so the
/// parsing, including the German BuyerReference (Leitweg-ID), is shared with the XRechnung reader.
/// </summary>
codeunit 11040 "E-Doc. PEPPOL BIS 3.0 DE Hdlr" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Reads a PEPPOL BIS 3.0 DE XML document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the XML document stream to be processed.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentXRechnungHandler: Codeunit "E-Document XRechnung Handler";
    begin
        exit(EDocumentXRechnungHandler.ReadIntoDraft(EDocument, TempBlob));
    end;

    /// <summary>
    /// Displays a readable view of the purchase information that was extracted from the document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document to be displayed.</param>
    /// <param name="TempBlob">A temporary blob containing the document data.</param>
    internal procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        EDocumentXRechnungHandler: Codeunit "E-Document XRechnung Handler";
    begin
        EDocumentXRechnungHandler.View(EDocument, TempBlob);
    end;
}
