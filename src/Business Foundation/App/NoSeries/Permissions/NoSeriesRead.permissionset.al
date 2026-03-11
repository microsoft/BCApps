// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 301 "No. Series - Read"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "No. Series - Objects";

    Permissions =
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = R,
        tabledata "No. Series Relationship" = R,
        tabledata "No. Series Tenant" = r;
}