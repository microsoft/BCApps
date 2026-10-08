// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6914 "Expense Attachment Enforcement"
{
    Access = Internal;
    Caption = 'Attachment Enforcement';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
}