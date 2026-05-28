// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Interfaces;

using Microsoft.eServices.EDocument;
using System.Utilities;

/// <summary>
/// Opt-in extension to "IDocumentReceiver". Connectors that surface inbound E-Document Messages
/// from their access point also implement this. Existing document-only connectors don't change.
///
/// Two stages, matching the document receive pattern, but with a typed buffer instead of opaque
/// metadata. The buffer carries an optional inline payload — connectors whose access point
/// returns content in the list call (batch APIs, webhook-buffered, etc.) set "Inlined" = true
/// and fill "Payload" during ListMessages; the framework then skips DownloadMessage for those rows.
/// </summary>
interface IDocumentReceiverMessages
{
    /// <summary>
    /// Stage 1 — list available inbound messages. Connector fills one buffer row per message.
    /// If the connector already has the payload (batch list, webhook queue, etc.) it calls
    /// "Buffer.SetPayload(TempBlob)" to inline it; the framework will not call DownloadMessage
    /// for that row.
    /// </summary>
    procedure ListMessages(var Service: Record "E-Document Service"; var Buffer: Record "E-Doc. Inbound Msg Buffer" temporary);

    /// <summary>
    /// Stage 2 — fetch the payload for one buffer row. Framework calls this only when the
    /// row was NOT inlined during ListMessages.
    /// </summary>
    procedure DownloadMessage(var Service: Record "E-Document Service"; Item: Record "E-Doc. Inbound Msg Buffer" temporary; var Payload: Codeunit "Temp Blob");
}
