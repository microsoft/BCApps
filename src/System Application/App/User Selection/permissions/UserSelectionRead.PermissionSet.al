// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment.Configuration;
using System.Security.AccessControl;

permissionset 9843 "User Selection - Read"
{
    Access = Public;
    Assignable = false;

    IncludedPermissionSets = "User Selection - Objects";

    Permissions = tabledata "Page Data Personalization" = R, // Page.Run requires this
                  tabledata User = r;
}