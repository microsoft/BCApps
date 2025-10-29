// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Enum extension for E-Document Process Draft with custom demo data implementation
/// </summary>
enumextension 5391 "EDoc Demo Read Into Draft" extends "E-Doc. Read into Draft"
{
    value(5370; "Demo Invoice")
    {
        Caption = 'Demo Invoice';
        Implementation = IStructuredFormatReader = "Demo Invoice Format Reader";
    }
}
