// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

permissionset 232 "Audit Codes - View"
{
    Assignable = false;
    Access = Internal;
    IncludedPermissionSets = "Audit Codes - Read";

    Permissions = tabledata "Reason Code" = I,
                tabledata "Return Reason" = I,
                tabledata "Source Code" = I,
                tabledata "Source Code Setup" = I;
}