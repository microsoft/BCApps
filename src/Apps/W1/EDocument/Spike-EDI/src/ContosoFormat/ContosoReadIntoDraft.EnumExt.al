// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Registers the Contoso structured-data handler with the V2.0 import pipeline. After build,
// configure the E-Document Service's "Read into Draft Impl." field to "Contoso Invoice" so the
// framework dispatches inbound XML through "Contoso Invoice Structured".
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 6953 "Contoso Read into Draft" extends "E-Doc. Read into Draft"
{
    value(6900; "Contoso Invoice")
    {
        Caption = 'Contoso Invoice';
        Implementation = IStructuredFormatReader = "Contoso Invoice Structured";
    }
}
