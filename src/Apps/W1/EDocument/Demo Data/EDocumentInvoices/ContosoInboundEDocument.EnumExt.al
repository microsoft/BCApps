// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Enum extension for E-Doc. Read into Draft to support Contoso Inbound E-Document invoices.
/// </summary>
enumextension 5392 "Contoso Inbound E-Document" extends "E-Doc. Read into Draft"
{
    value(5370; "Demo Invoice")
    {
        Caption = 'Demo Invoice';
        Implementation = IStructuredFormatReader = "Contoso Inb.Inv. Handler";
    }
}
