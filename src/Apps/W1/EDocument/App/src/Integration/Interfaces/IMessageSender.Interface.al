// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Sends a child message associated with an E-Document through a service integration.
/// </summary>
interface IMessageSender
{
    /// <summary>
    /// Sends the payload in the message context.
    /// </summary>
    /// <param name="EDocument">The parent E-Document.</param>
    /// <param name="EDocumentService">The service used to send the message.</param>
    /// <param name="MessageContext">The message payload, transport state, and result. The implementation must set the result to Sent or Pending Response after successful transmission.</param>
    /// <remarks>
    /// The implementation is responsible for obtaining any privacy consent required by the external service before transmitting data.
    /// Implementations must use MessageContext.GetMessageEntryNo() as an idempotency key because a message can be retried after an ambiguous transport failure.
    /// Set the context status to Pending Response when the external service accepted the message but requires asynchronous response polling.
    /// </remarks>
    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context");
}