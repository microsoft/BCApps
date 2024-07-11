// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Apps;
using System.Integration;

permissionset 7210 "D365 ATTACH DEBUG"
{
    Access = Public;
    Assignable = true;
    Caption = 'Attach Debug';

    IncludedPermissionSets = "VSC Intgr. - Admin";

    Permissions = system "Attach debugger to other user's session." = X,
                  tabledata "Published Application" = R;
}
