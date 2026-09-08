// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.RoleCenters;

pageextension 6904 "Exp. Accountant RC Ext" extends "Accountant Role Center"
{
    layout
    {
        addlast(rolecenter)
        {
            part("Expense Activities"; "Expense Activities")
            {
                AccessByPermission = tabledata Expense = R;
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
