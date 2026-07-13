// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

enum 6787 "Withholding Threshold Base"
{
    Extensible = true;
    Caption = 'Withholding Threshold Base';

    value(0; Record)
    {
        Caption = 'Record/Line';
    }
    value(1; Document)
    {
        Caption = 'Document';
    }
    value(2; "Category Period")
    {
        Caption = 'Category in Period';
    }
    value(3; "Total Period")
    {
        Caption = 'Total in Period';
    }
}
