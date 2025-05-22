// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

permissionset 231 "Audit Codes - Read"
{
    Assignable = false;
    Access = Internal;
    IncludedPermissionSets = "Audit Codes - Objects";

    Permissions = tabledata "Reason Code" = R,
                tabledata "Return Reason" = R,
                tabledata "Source Code" = R,
                tabledata "Source Code Setup" = R;
}