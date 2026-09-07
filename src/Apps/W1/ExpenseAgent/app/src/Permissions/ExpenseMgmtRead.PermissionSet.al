// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

permissionset 6907 "Expense Mgmt. Read"
{
    Caption = 'Expense Management - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "Expense Mgmt. Read Data";

    Permissions =
        tabledata "Spend Request" = R,
        tabledata "Spend Request Detail" = R,
        tabledata "Spend Request To G/L Link" = R;
}