// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

enum 6786 "Withholding Calculation Method"
{
    Extensible = true;
    Caption = 'Withholding Calculation Method';

    value(0; Simple)
    {
        Caption = 'Simple';
    }
    value(1; Compound)
    {
        Caption = 'Compound';
    }
}
