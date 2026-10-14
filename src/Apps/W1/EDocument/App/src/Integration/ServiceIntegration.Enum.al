// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;

enum 6151 "Service Integration" implements IDocumentSender, IDocumentReceiver, IConsentManager, IMessageSender, IMessageResponseHandler
{
    Extensible = true;
    Access = Public;
    DefaultImplementation = IConsentManager = "Consent Manager Default Impl.",
                            IMessageSender = "E-Doc. Msg. Transport Default",
                            IMessageResponseHandler = "E-Doc. Msg. Transport Default";
    UnknownValueImplementation = IDocumentSender = "E-Document No Integration",
                                 IDocumentReceiver = "E-Document No Integration",
                                 IConsentManager = "E-Document No Integration",
                                 IMessageSender = "E-Doc. Msg. Transport Default",
                                 IMessageResponseHandler = "E-Doc. Msg. Transport Default";

    value(0; "No Integration")
    {
        Caption = ' ';
        Implementation = IDocumentSender = "E-Document No Integration", IDocumentReceiver = "E-Document No Integration", IConsentManager = "E-Document No Integration";
    }
}
