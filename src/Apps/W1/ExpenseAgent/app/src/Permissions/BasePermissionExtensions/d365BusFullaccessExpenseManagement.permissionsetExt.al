// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

permissionsetextension 6901 "D365 BUS FULL ACCESS Expense Management" extends "D365 BUS FULL ACCESS"
{
    IncludedPermissionSets = "Expense Mgmt. Admin";
}