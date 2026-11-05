// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6915 "Expense Partial Day Rules"
{
    Access = Internal;
    Caption = 'Partial Day Rules';

    value(0; "Flat Percentage Of Full Rate")
    {
        Caption = 'Flat Percentage of Full Rate';
    }
    value(1; "Based On Eligible Hours")
    {
        Caption = 'Based on Eligible Hours';
    }
}