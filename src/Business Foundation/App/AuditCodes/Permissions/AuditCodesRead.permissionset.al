// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

permissionset 231 "Audit Codes - Read"
{
    Assignable = false;
    Access = Internal;

    Permissions = tabledata "Reason Code" = r,
                tabledata "Return Reason" = r,
                tabledata "Source Code" = r,
                tabledata "Source Code Setup" = r;
}