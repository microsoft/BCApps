// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Polls the asynchronous response for an outgoing child E-Document message.
/// </summary>
interface IMessageResponseHandler
{
    /// <summary>
    /// Polls the external service for the response to a previously sent child message.
    /// </summary>
    /// <param name="EDocument">The parent E-Document.</param>
    /// <param name="EDocumentService">The service used to send the message.</param>
    /// <param name="MessageContext">The original message context and transport diagnostics.</param>
    /// <returns>True when the response is complete; otherwise false.</returns>
    /// <remarks>
    /// A completed response must set the context status to Sent. A response that is not ready must set it to Pending Response.
    /// Implementations must use MessageContext.GetMessageEntryNo() to correlate the external request.
    /// The E-Document Core app does not provide connector endpoint, authentication, or response parsing behavior.
    /// A connector or integration adapter must implement those transport-specific responsibilities.
    /// </remarks>
    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context"): Boolean;
}