// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Adds "Contoso Connector" as a selectable value on the E-Document Service's "Service Integration V2"
// field. The enum's declared interfaces (IDocumentSender, IDocumentReceiver) are bound to the
// Contoso Connector codeunit. The opt-in message-extension interfaces (IDocumentSenderMessages,
// IDocumentReceiverMessages) are NOT declared on the enum — the framework discovers them at
// runtime via `is` / `as` on the bound codeunit.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Interfaces;

enumextension 6952 "Contoso Integration" extends "Service Integration"
{
    value(6900; "Contoso Connector")
    {
        Caption = 'Contoso Connector (Spike)';
        Implementation = IDocumentSender = "Contoso Connector", IDocumentReceiver = "Contoso Connector";
    }
}
