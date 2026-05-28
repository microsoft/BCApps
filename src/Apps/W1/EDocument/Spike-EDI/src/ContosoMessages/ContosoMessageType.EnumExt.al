// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Implementer code. Extends the framework's "E-Document Message Type" enum with one Contoso
// message — an acknowledgement of an invoice's receipt status. Bi-directional (Type supports
// both Incoming and Outgoing).
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;

enumextension 6951 "Contoso Message Type Ext" extends "E-Document Message Type"
{
    value(6900; "Contoso Invoice Ack")
    {
        Caption = 'Contoso Invoice Ack';
        Implementation = IEDocumentMessageType = "Contoso Ack Type";
    }
}
