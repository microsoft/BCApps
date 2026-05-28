// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Utilities;

/// <summary>
/// Outbound IO for an E-Document Message — produces the wire payload bytes from the parent
/// E-Document and contextual data the Type captured. Pure write; does not transmit. Transport
/// goes through "IDocumentSenderMessages.SendMessage" (the opt-in extension to IDocumentSender).
/// Post-send state transitions go through "IEDocumentMessageType.ApplyMessage".
/// </summary>
interface IEDocumentMessageWriter
{
    /// <summary>
    /// Fills the TempBlob with the outbound payload, and may set Msg fields
    /// (e.g., "Status Code") that "Type.ApplyMessage" will read after successful send.
    /// </summary>
    procedure GenerateMessage(Related: Record "E-Document"; var Msg: Record "E-Document Message"; var TempBlob: Codeunit "Temp Blob"): Boolean;
}
