// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6989 "Expense Policy Status"
{
    Extensible = false;
    Access = Internal;

    value(0; "Not Evaluated")
    {
        Caption = 'Not Evaluated';
    }
    value(1; Flagged)
    {
        Caption = 'Flagged';
    }
    value(2; Cleared)
    {
        Caption = 'Cleared';
    }
    value(3; Stale)
    {
        Caption = 'Needs Recheck';
    }
    value(4; "No Policies")
    {
        Caption = 'No Policies';
    }
}
