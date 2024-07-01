// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Reflection;
using System.Tooling;
using System.Privacy;
using System.Utilities;
using System.Integration;
using System.Environment.Configuration;
using System.Environment;
using System.Globalization;

permissionset 162 "SECURITY (System)"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Company - Edit",
                             "Permissions & Licenses - Edit",
                             "Session - Edit";

    Permissions = system "Tools, Security, Roles" = X,
                  tabledata "Add-in" = imd,
                  tabledata "All Profile" = IMD,
                  tabledata "All Profile Extension" = IMD,
                  tabledata "All Profile Page Metadata" = IMD,
                  tabledata AllObj = imd,
                  tabledata AllObjWithCaption = Rimd,
#if not CLEAN22
#pragma warning disable AL0432
                  tabledata Chart = imd,
#pragma warning restore AL0432
#endif
                  tabledata "Code Coverage" = Rimd,
                  tabledata "Data Sensitivity" = RIMD,
                  tabledata Date = imd,
                  tabledata "Document Service" = imd,
                  tabledata "Document Service Scenario" = imd,
                  tabledata Entitlement = imd,
                  tabledata "Entitlement Set" = imd,
                  tabledata "Feature Key" = RIMD,
                  tabledata Field = Rimd,
                  tabledata Integer = Rimd,
                  tabledata "Intelligent Cloud" = Rimd,
                  tabledata "Intelligent Cloud Status" = Rimd,
                  tabledata Key = Rimd,
                  tabledata "License Information" = imd,
                  tabledata "License Permission" = imd,
                  tabledata "Membership Entitlement" = imd,
                  tabledata "NAV App Setting" = RIMD,
                  tabledata "Object Metadata" = imd,
#pragma warning disable AL0432 // Disabling deprecation warning since these tables are being moved on prem and hence still need permissions
                  tabledata Permission = imd,
                  tabledata "Permission Set" = imd,
#pragma warning restore AL0432
                  tabledata "Permission Range" = imd,
                  tabledata "Profile Configuration Symbols" = IMD,
                  tabledata "Server Instance" = imd,
                  tabledata "SID - Account ID" = Rimd,
                  tabledata "System Object" = imd,
                  tabledata "Table Information" = Rimd,
                  tabledata "Tenant Profile" = IMD,
                  tabledata "Tenant Profile Extension" = IMD,
                  tabledata "Tenant Profile Page Metadata" = IMD,
                  tabledata "Tenant Profile Setting" = IMD,
                  tabledata User = RMD,
                  tabledata "User Property" = Rimd,
                  tabledata "Windows Language" = imd;
}