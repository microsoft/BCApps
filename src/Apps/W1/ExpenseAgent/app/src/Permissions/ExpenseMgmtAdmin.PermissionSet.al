// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

permissionset 6905 "Expense Mgmt. Admin"
{
    Assignable = true;
    Caption = 'Expense Management - Admin';

    IncludedPermissionSets = "Expense Mgmt. Edit",
                             "Expense Mgmt. Admin Data";
}