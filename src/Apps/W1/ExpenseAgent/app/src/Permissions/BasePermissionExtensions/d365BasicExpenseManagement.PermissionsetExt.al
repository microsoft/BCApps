// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

permissionsetextension 6900 "D365 BASIC Expense Management" extends "D365 BASIC"
{
    IncludedPermissionSets = "Expense Mgmt. Edit";
}