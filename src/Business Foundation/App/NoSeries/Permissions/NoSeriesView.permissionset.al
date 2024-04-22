// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 303 "No. Series - View"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "No. Series - Read";

    Permissions =
#if not CLEAN24
        tabledata "No. Series Line" = m,
#pragma warning disable AL0432
        tabledata "No. Series Line Sales" = m,
        tabledata "No. Series Line Purchase" = m,
#pragma warning restore AL0432
#endif
        tabledata "No. Series Tenant" = imd;
}