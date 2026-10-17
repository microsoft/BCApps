// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Expense No Receipt Type"
{
    Access = Internal;
    Caption = 'No Receipt Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Lost Receipt")
    {
        Caption = 'Lost Receipt';
    }
}
