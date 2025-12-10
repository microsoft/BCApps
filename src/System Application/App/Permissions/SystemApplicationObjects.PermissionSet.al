// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Apps;
using System.Azure.Identity;
using System.DataAdministration;
using System.Device;
using System.Email;
using System.Environment.Configuration;
using System.ExternalFileStorage;
using System.Globalization;
using System.Integration;
using System.Integration.Excel;
using System.Integration.Sharepoint;
using System.Integration.Word;
using System.MCP;
using System.Privacy;
using System.Reflection;
using System.Security.Encryption;
using System.Security.User;
using System.Text;
using System.Tooling;
using System.Utilities;
using System.Visualization;

permissionset 219 "System Application - Objects"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Advanced Settings - Objects",
                             "Azure AD Plan - Objects",
                             "AAD User Management - Objects",
                             "Cryptography Mgt. - Objects",
                             "Cues and KPIs - Objects",
                             "Data Classification - Objects",
                             "Document Sharing - Objects",
                             "Edit in Excel - Objects",
                             "Email - Objects",
                             "Entity Text - Objects",
                             "Extension Management - Objects",
                             "Feature Key - Objects",
                             "File Storage - Objects",
                             "Guided Experience - Objects",
                             "Language - Objects",
                             "MCP - Objects",
                             "Page Summary Provider - Obj.",
                             "Performance Profiler - Objects",
                             "Permission Sets - Objects",
                             "Printer Management - Objects",
                             "Record Link Management - Obj.",
                             "Retention Policy - Objects",
                             "Security Groups - Objects",
                             "SharePoint API - Objects",
                             "Table Information - Objects",
                             "Table Key - Objects",
                             "Translation - Objects",
                             "User Permissions - Objects",
                             "User Selection - Objects",
                             "User Settings - Objects",
                             "Web Service Management - Obj.",
                             "Word Templates - Objects";
}
