// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Lets a document format declare which message type (if any) should be emitted as a response
/// for a received E-Document. Bound to the "E-Document Format" enum.
/// </summary>
interface IEDocResponseProvider
{
    /// <summary>
    /// Returns the message type to emit as a response for the given E-Document,
    /// or Unknown when no response message applies.
    /// EDocument."Process Draft Impl." is already set when this is called, so implementations can inspect the draft type.
    /// </summary>
    /// <param name="EDocument">The E-Document record with "Process Draft Impl." populated.</param>
    /// <returns>The message type to build, or Unknown for none.</returns>
    procedure GetResponseMessageType(EDocument: Record "E-Document"): Enum "E-Document Message Type";
}
