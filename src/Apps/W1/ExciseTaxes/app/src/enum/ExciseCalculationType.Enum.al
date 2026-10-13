// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

enum 7415 "Excise Calculation Type"
{
    Caption = 'Excise Calculation Type';
    Extensible = true;

    value(0; "Specific per Unit")
    {
        Caption = 'Specific - per unit';
    }
    value(1; "Ad valorem")
    {
        Caption = 'Ad valorem';
    }
    value(2; Hybrid)
    {
        Caption = 'Hybrid';
    }
}