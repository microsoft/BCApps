// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;
using System.Environment;

permissionset 2718 "Page Summary - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'Page Summary Provider - Admin';

    IncludedPermissionSets = "Page Summary Provider - Read";

    Permissions = tabledata "Page Summary Settings" = IMD,
                   tabledata "Tenant Media Set" = i;
}