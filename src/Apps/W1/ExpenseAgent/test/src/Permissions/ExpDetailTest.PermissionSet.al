// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Security.AccessControl;

permissionset 148303 "Exp. Detail Test"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "D365 READ";

    // Keep the header read-only, while allowing the page to modify a detail indirectly.
    Permissions = tabledata "Spend Request Detail" = m,
                  codeunit Assert = X,
                  codeunit "Library - Lower Permissions" = X;
}
