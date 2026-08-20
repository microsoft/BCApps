// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Interfaces;

enumextension 148151 "FR Service Integration" extends "Service Integration"
{
    value(148150; "FR Message Mock")
    {
        Implementation = IDocumentSender = "FR E-Doc. Msg. Sender Mock", IDocumentReceiver = "FR E-Doc. Msg. Sender Mock", IConsentManager = "FR E-Doc. Msg. Sender Mock", IMessageSender = "FR E-Doc. Msg. Sender Mock";
    }
}