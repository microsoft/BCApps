// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Expense Activity Compliance"
{
    Access = Internal;
    Extensible = false;

    value(0; NotChecked)
    {
        Caption = 'Not checked';
    }
    value(1; Compliant)
    {
        Caption = 'Compliant';
    }
    value(2; NonCompliant)
    {
        Caption = 'Non-compliant';
    }
}
