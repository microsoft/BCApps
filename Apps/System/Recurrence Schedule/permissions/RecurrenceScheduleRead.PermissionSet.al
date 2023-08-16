// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DateTime;

using System.Utilities;

permissionset 4690 "Recurrence Schedule - Read"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Recurrence Schedule - Objects";

    Permissions = tabledata Date = r,
                  tabledata "Recurrence Schedule" = r;
}
