// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 28006 "PINT A-NZ EDoc Read into Draft" extends "E-Doc. Read into Draft"
{
    value(28005; "PINT A-NZ")
    {
        Caption = 'PINT A-NZ';
        Implementation = IStructuredFormatReader = "E-Document PINT A-NZ Handler";
    }
}
