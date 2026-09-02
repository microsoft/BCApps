// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.CFDI;

enumextension 3303 "E-Document Format MX" extends "E-Document Format"
{
    value(3303; CFDI)
    {
        Implementation = "E-Document" = "EDoc CFDI MX";
        Caption = 'CFDI / Carta Porte';
    }
}