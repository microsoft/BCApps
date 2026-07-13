// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

enum 6785 "Withholding Calculation Base"
{
    Extensible = true;
    Caption = 'Withholding Calculation Base';

    value(0; Gross)
    {
        Caption = 'Gross';
    }
    value(1; Net)
    {
        Caption = 'Net (Gross-up)';
    }
}
