// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

tableextension 3376 "E-Document MX" extends "E-Document"
{
    fields
    {
        field(3390; "CFDI Cancellation ID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'CFDI Cancellation ID';
        }
    }
}
