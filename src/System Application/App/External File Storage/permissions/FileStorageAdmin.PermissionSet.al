// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

permissionset 9450 "File Storage - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'External File Storage - Admin';

    IncludedPermissionSets = "File Storage - Edit";

    Permissions =
        tabledata "Ext. File Storage Connector" = RIMD,
        tabledata "File Storage Connector Logo" = RIMD,
        tabledata "File Account Scenario" = RIMD,
        tabledata "File Scenario" = RIMD,
        tabledata "File Account Content" = RIMD;
}
