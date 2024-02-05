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
#if not CLEAN24
#pragma warning disable AL0432
        tabledata "No. Series Line Sales" = R,
        tabledata "No. Series Line Purchase" = R,
#pragma warning restore AL0432
#endif
        tabledata "No. Series Relationship" = R,
        tabledata "No. Series Tenant" = r;
}