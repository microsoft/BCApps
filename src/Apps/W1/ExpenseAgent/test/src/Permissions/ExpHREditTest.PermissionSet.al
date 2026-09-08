// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using System.Security.AccessControl;

permissionset 148301 "Exp. HR Edit Test"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "D365 BASIC ISV",
                             "D365 HR, EDIT";

    Permissions = codeunit Assert = X,
                  codeunit "Library - Lower Permissions" = X;
}
