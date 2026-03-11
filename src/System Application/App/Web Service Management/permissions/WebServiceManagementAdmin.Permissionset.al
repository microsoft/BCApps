// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;
using System.Environment.Configuration;

permissionset 6712 "Web Service Management - Admin"
{
    Access = Public;
    Assignable = false;

    IncludedPermissionSets = "Web Service Management - View",
                             "Feature Mgt. - Admin";

    Permissions = tabledata "Tenant Web Service" = IMD,
                  tabledata "Tenant Web Service Columns" = IMD,
                  tabledata "Tenant Web Service Filter" = IMD,
                  tabledata "Tenant Web Service OData" = IMD,
                  tabledata "Web Service" = IMD,
                  tabledata "Web Service Aggregate" = IMD;
}