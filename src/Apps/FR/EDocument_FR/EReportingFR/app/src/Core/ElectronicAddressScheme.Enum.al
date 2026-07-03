// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10976 "Electronic Address Scheme"
{
    Extensible = true;

    value(0; "EM")
    {
        Caption = 'Email (EM)';
    }
    value(1; "0009")
    {
        Caption = 'SIRET (0009)';
    }
    value(2; "0002")
    {
        Caption = 'SIREN (0002)';
    }
}
