// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 304 "No. Series - Admin"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "No. Series - View";

    Permissions =
        tabledata "No. Series" = IMD,
        tabledata "No. Series Line" = IMD,
#if not CLEAN24
#pragma warning disable AL0432
        tabledata "No. Series Line Sales" = IMD,
        tabledata "No. Series Line Purchase" = IMD,
#pragma warning restore AL0432
#endif
        tabledata "No. Series Relationship" = IMD;
}