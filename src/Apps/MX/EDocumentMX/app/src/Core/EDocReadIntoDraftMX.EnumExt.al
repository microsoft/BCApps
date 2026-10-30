// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 3355 "EDoc Read Into Draft MX" extends "E-Doc. Read into Draft"
{
    value(3355; "CFDI MX")
    {
        Caption = 'CFDI MX';
        Implementation = IStructuredFormatReader = "EDoc CFDI Read Draft MX";
    }
}
