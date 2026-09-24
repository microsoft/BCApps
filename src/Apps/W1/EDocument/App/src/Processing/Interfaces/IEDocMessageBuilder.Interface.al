// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

/// <summary>
/// Builds the payload of an E-Document message. Bound to the "E-Document Message Type" enum,
/// so each message type value dispatches to the codeunit that knows how to build it.
/// Extend "E-Document Message Type" with your own value and bind it to your implementation
/// to provide a new message format.
/// </summary>
interface IEDocMessageBuilder
{
    /// <summary>
    /// Builds the message payload for the given E-Document into TempBlob.
    /// </summary>
    /// <param name="EDocument">The E-Document the message relates to.</param>
    /// <param name="ResponseType">The response type dimension of the message (e.g. Acknowledged, Accepted, Rejected). None for messages that are not responses.</param>
    /// <param name="TempBlob">The blob to write the payload into.</param>
    procedure BuildMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob");
}
