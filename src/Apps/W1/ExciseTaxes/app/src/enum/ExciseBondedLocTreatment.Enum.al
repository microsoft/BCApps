// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

enum 7417 "Excise Bonded Loc. Treatment"
{
    Caption = 'Bonded Location Treatment';
    Extensible = true;

    value(0; Ignore)
    {
        Caption = 'Ignore';
    }
    value(1; Suspend)
    {
        Caption = 'Suspend';
    }
}