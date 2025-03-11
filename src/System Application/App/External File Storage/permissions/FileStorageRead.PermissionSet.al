// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Environment;

permissionset 9451 "File Storage - Read"
{
    Access = Internal;
    Assignable = false;
    Caption = 'External File Storage - Read';
    IncludedPermissionSets = "File Storage - Objects";

    Permissions =
        tabledata "Ext. File Storage Connector" = r,
        tabledata "File Storage Connector Logo" = r,
        tabledata "File Account Scenario" = r,
        tabledata "File Scenario" = r,
        tabledata "File Account Content" = r,
        tabledata Media = r; // This permission is required by External File Storage Account Wizard
}