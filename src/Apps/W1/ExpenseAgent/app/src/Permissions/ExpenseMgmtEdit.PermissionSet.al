// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

permissionset 6906 "Expense Mgmt. Edit"
{
    Assignable = true;
    Caption = 'Expense Management - Edit';

    IncludedPermissionSets = "Expense Mgmt. Read",
                             "Expense Mgmt. Edit Data";

    Permissions =
        tabledata "Spend Request" = IMD,
        tabledata "Spend Request Detail" = IMD,
        // The base request delete trigger removes ledger links after its spent-amount check.
        tabledata "Spend Request To G/L Link" = D;
}