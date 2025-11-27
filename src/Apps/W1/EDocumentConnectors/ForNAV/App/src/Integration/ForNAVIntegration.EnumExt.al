// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Interfaces;

enumextension 6410 "ForNAV Integration" extends "Service Integration"
{
    value(6410; "FORNAV")
    {
        Implementation = IDocumentSender = "ForNAV Integration Impl.", IDocumentReceiver = "ForNAV Integration Impl.", IConsentManager = "ForNAV Integration Impl.";
    }
}