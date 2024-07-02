// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

permissionset 233 "Audit Codes - Admin"
{
    Assignable = false;
    Access = Internal;
    IncludedPermissionSets = "Audit Codes - View";

    Permissions = tabledata "Reason Code" = MD,
                tabledata "Return Reason" = MD,
                tabledata "Source Code" = MD,
                tabledata "Source Code Setup" = MD;
}