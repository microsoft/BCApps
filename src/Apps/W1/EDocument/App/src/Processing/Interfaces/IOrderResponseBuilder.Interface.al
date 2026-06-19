// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.Peppol.Response;
using System.Utilities;

/// <summary>
/// Allows a format reader to build an outbound order response for a received e-document.
/// Separate from IStructuredFormatReader to avoid a breaking change on that interface.
/// </summary>
interface IOrderResponseBuilder
{

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
