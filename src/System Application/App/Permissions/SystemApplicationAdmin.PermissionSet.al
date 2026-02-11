// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Apps;
using System.DataAdministration;
using System.Email;
using System.Environment.Configuration;
using System.ExternalFileStorage;
using System.Integration;
using System.Integration.Excel;
using System.MCP;
using System.Privacy;
using System.SFTPClient;

permissionset 154 "System Application - Admin"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "System Application - Basic",
                             "Company - Edit",
                             "D365 ATTACH DEBUG",
                             "D365 BACKUP/RESTORE",
                             "D365 SNAPSHOT DEBUG",
                             "Data Cleanup - Admin",
                             "Email - Admin",
                             "Exten. Mgt. - Admin",
                             "Edit in Excel-Admin",
                             "Feature Key - Admin",
                             "File Storage - Admin",
                             "MCP - Admin",
                             "Permissions & Licenses - Edit",
                             "Priv. Notice - Admin",
                             "Retention Policy - Admin",
                             "PageScripting - Play",
                             "Page Summary - Admin",
                             "SFTP - Admin",
                             "TROUBLESHOOT TOOLS",
                             "VSC Intgr. - Admin";
}
