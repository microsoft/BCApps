// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;

tableextension 3356 "EDoc Purchase Header MX" extends "E-Document Purchase Header"
{
    fields
    {
        field(3352; "Fiscal Invoice Number PAC"; Text[50])
        {
            Caption = 'Fiscal Invoice Number PAC';
            DataClassification = CustomerContent;
        }
    }
}
