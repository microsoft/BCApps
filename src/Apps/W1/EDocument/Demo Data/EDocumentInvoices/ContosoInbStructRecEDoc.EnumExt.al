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
enumextension 5391 "Contoso Inb. Struct.Rec. E-Doc" extends "Structure Received E-Doc."
{
    value(5370; "Demo Invoice")
    {
        Caption = 'Demo Invoice';
        Implementation = IStructureReceivedEDocument = "Contoso Inb.Inv. Handler";
    }
}
