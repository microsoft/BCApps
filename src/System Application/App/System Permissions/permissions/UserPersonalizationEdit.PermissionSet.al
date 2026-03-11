// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Environment.Configuration;

permissionset 91 "User Personalization - Edit"
{
    Access = Public;
    Assignable = false;

    IncludedPermissionSets = "User Personalization - Read";

    Permissions = tabledata "Page Data Personalization" = IMD,
                  tabledata "User Default Style Sheet" = IMD,
                  tabledata "User Personalization" = IMD,
                  tabledata "User Page Metadata" = IMD;
}
