// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Peppol.Response;
using System.Utilities;

/// <summary>
/// Specifies how a structured data type should be interpreted and read into a draft.
/// A structure data type is a textual representation of the e-document that is stored in a TempBlob to allow different encodings.
/// </summary>
interface IStructuredFormatReader
{

    /// <summary>
    /// Read the data into the E-Document data structures.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="TempBlob">The temporary blob that contains the data to read</param>
    /// <returns>The data process to run on the structured data.</returns>
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft";


    /// <summary>
    /// Presents a view of the data
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="TempBlob">The temporary blob that contains the data to read</param>
    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob");

    /// <summary>
    /// Returns whether this format reader expects an order response to be sent back to the sender for the given E-Document.
    /// Format apps that generate outbound response messages (e.g. PEPPOL Order Response) implement this to signal eligibility.
    /// EDocument."Process Draft Impl." is already set when this is called, so implementations can inspect the draft type.
    /// </summary>
    /// <param name="EDocument">The E-Document record with "Process Draft Impl." populated.</param>
    /// <returns>True if an order response should be generated; false otherwise.</returns>
    procedure SupportsOrderResponse(EDocument: Record "E-Document"): Boolean;

    /// <summary>
    /// Builds a format-specific order response XML blob into TempBlob.
    /// Called by the framework after ReadIntoDraft (for AB) and after Sales Order release (for AC).
    /// Implementations that return false from SupportsOrderResponse may leave TempBlob empty.
    /// </summary>
    procedure BuildOrderResponse(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob");

}