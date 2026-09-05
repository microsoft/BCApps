// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

enum 7415 "Excise Duty Calculation Type"
{
    Extensible = true;

    value(0; Specific)
    {
        Caption = 'Specific';
    }
    value(1; "Ad Valorem")
    {
        Caption = 'Ad Valorem';
    }
    value(2; Hybrid)
    {
        Caption = 'Hybrid';
    }
}
