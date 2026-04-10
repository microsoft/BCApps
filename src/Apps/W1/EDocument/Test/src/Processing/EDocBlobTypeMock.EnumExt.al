// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 139781 "E-Doc Blob Type Mock" extends "E-Doc. Read into Draft"
{
    value(139781; "PDF Mock")
    {
        Implementation = IStructuredFormatReader = "E-Doc PDF Mock";
    }
}