// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Apps;
using System.Azure.Identity;
using System.DataAdministration;
using System.Device;
using System.Environment;
using System.Environment.Configuration;
using System.ExternalFileStorage;
#if not CLEAN28
using System.Feedback;
#endif
using System.Globalization;
using System.Integration;
using System.Integration.Excel;
using System.Integration.Word;
using System.MCP;
using System.Privacy;
using System.Reflection;
using System.Security.User;
using System.Utilities;
using System.Visualization;

permissionset 21 "System Application - Read"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "System Application - Objects",
                             "Azure AD Plan - Read",
                             "Azure AD User - Read",
                             "AAD User Management - Exec",
                             "BLOB Storage - Exec",
                             "Cues and KPIs - Read",
                             "Data Classification - Read",
                             "Default Role Center - Read",
                             "Edit in Excel - Read",
                             "Extension Management - Read",
                             "Feature Key - Read",
                             "Field Selection - Read",
                             "File Storage - Read",
                             "Guided Experience - Read",
                             "Headlines - Read",
                             "MCP - Read",
                             "Object Selection - Read",
                             "Page Summary Provider - Read",
                             "Page Action Provider - Read",
                             "Printer Management - Read",
                             "Record Link Management - Read",
                             "Retention Policy - Read",
                             "Environment Cleanup - Read",
#if not CLEAN28
                             "Satisfaction Survey - Read",
#endif
                             "System Initialization - Exec",
                             "Security Groups - Read",
                             "Table Information - Read",
                             "Tenant License State - Read",
                             "Translation - Read",
                             "User Permissions - Read",
                             "User Selection - Read",
                             "Web Service Management - Read",
                             "Word Templates - Read";
}
