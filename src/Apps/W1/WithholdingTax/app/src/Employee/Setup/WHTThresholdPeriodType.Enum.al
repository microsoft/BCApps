// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

enum 6788 "WHT Threshold Period Type"
{
    Extensible = true;
    Caption = 'Withholding Threshold Period Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Month)
    {
        Caption = 'Month';
    }
    value(2; Quarter)
    {
        Caption = 'Quarter';
    }
    value(3; Year)
    {
        Caption = 'Year';
    }
    value(4; "Fiscal Period")
    {
        Caption = 'Fiscal Period';
    }
}
