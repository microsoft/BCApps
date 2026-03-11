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
        tabledata "No. Series Tenant" = imd;
}