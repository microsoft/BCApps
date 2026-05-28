// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Interfaces;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Send;

/// <summary>
/// Opt-in extension to "IDocumentSender". Connectors that handle outbound E-Document Messages
/// (in addition to outbound Documents) also implement this interface. Existing connectors that
/// don't care about messages don't change. The framework uses `is` / `as` to test for support —
/// same idiom as "ISentDocumentActions" extending IDocumentSender today.
/// </summary>
interface IDocumentSenderMessages
{
    /// <summary>
    /// Sends an outbound Message via the connector. The SendContext.TempBlob carries the payload
    /// the Writer produced. The Message record gives the connector access to type, status code,
    /// parent reference, service, etc. — anything it needs to route correctly.
    /// </summary>
    procedure SendMessage(var Msg: Record "E-Document Message"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext);
}
