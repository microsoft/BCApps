// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

/// <summary>
/// Optional extension of IEDocMessageBuilder for builders whose response type is only known while building,
/// for example an order response that becomes Conditionally Accepted because the seller changed the order.
/// Implement it on the same codeunit that implements IEDocMessageBuilder; callers detect it and store the
/// returned response type on the message. Builders that do not implement it keep the requested response type.
/// </summary>
interface IEDocResponseMessageBuilder
{
    /// <summary>
    /// Builds the response message payload for the given E-Document into TempBlob.
    /// </summary>
    /// <param name="EDocument">The E-Document the message relates to.</param>
    /// <param name="RequestedResponseType">The response type the caller asks for (e.g. Acknowledged, Accepted, Rejected).</param>
    /// <param name="TempBlob">The blob to write the payload into.</param>
    /// <returns>The response type of the payload that was built, for example Conditionally Accepted for a requested Accepted.</returns>
    procedure BuildResponseMessage(EDocument: Record "E-Document"; RequestedResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Response Type";
}
