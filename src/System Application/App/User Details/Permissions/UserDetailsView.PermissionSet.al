// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Security.AccessControl;
using System.Environment.Configuration;

permissionset 775 "User Details - View"
{
    Assignable = false;

    IncludedPermissionSets = "User Details - Objects";

    Permissions = tabledata User = r,
                  tabledata "User Personalization" = r,
                  tabledata "User Property" = r;
}