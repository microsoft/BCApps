// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Environment.Configuration;

permissionset 2 "No. Series - Admin"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "No. Series - Object";

    Permissions = tabledata "No. Series" = RIMD,
        tabledata "No. Series Line" = RIMD,
#if not CLEAN24
#pragma warning disable AL0432
        tabledata "No. Series Line Sales" = RIMD,
        tabledata "No. Series Line Purchase" = RIMD,
#pragma warning restore AL0432
#endif
        tabledata "No. Series Relationship" = RIMD,
        tabledata "Page Data Personalization" = R,
        tabledata "No. Series Tenant" = rimd;
}