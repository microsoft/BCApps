// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Environment;

permissionset 9453 "File Storage - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'External File Storage - Edit';

    IncludedPermissionSets = "File Storage - Read";

    Permissions = tabledata "File Storage Connector Logo" = imd,
                  tabledata "Tenant Media" = imd;
}