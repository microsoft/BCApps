// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

enum 7416 "Excise Bonded Handling"
{
    Extensible = true;

    value(0; "Not Bonded")
    {
        Caption = 'Not Bonded';
    }
    value(1; Bonded)
    {
        Caption = 'Bonded';
    }
    value(2; Customs)
    {
        Caption = 'Customs';
    }
}