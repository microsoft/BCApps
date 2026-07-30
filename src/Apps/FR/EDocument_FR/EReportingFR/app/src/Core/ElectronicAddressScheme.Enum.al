// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10976 "Electronic Address Scheme"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "EM")
    {
        Caption = 'Email (EM)';
    }
    value(2; "0009")
    {
        Caption = 'SIRET (0009)';
    }
    value(3; "0002")
    {
        Caption = 'SIREN (0002)';
    }
    value(4; "0223")
    {
        Caption = 'French VAT number (0223)';
    }
    value(5; "0225")
    {
        Caption = 'French routing identifier (0225)';
    }
}
