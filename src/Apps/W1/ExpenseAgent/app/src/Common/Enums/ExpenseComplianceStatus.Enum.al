// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6926 "Expense Compliance Status"
{
    Access = Internal;
    Caption = 'Compliance Status';

    value(0; "Not Evaluated")
    {
        Caption = 'Not Evaluated';
    }
    value(1; Compliant)
    {
        Caption = 'Compliant';
    }
    value(2; "Non-Compliant")
    {
        Caption = 'Non-Compliant';
    }
}
