// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;

enumextension 3352 "Service Integration MX" extends "Service Integration"
{

    value(3300; "Interfactura Service")
    {
        Implementation =
                IDocumentSender = "MX Interfactura Impl.",
                IDocumentReceiver = "MX Interfactura Impl.",
                IMessageSender = "MX Interfactura Impl.",
                IMessageResponseHandler = "MX Interfactura Impl.";

        Caption = 'Interfactura';
    }

}
