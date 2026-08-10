// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

permissionsetextension 6903 "D365 TEAM MEMBER Expense Management" extends "D365 TEAM MEMBER"
{
    IncludedPermissionSets = "Expense Mgmt. Edit";
}