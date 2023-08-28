// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Azure.Identity;
using System.Utilities;
using System.Visualization;
using System.Privacy;
using System.Environment.Configuration;
using System.Integration.Excel;
using System.Reflection;
using System.Globalization;
using System.Integration;
using System.Device;
using System.DateTime;
using System.DataAdministration;
using System.Telemetry;
using System.Environment;
using System.Upgrade;
using System.Security.User;
using System.Media;
using System.Integration.Word;
using System.Feedback;

permissionset 21 "System Application - Read"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "System Application - Objects",
                             "Azure AD Licensing - Exec",
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
                             "Guided Experience - Read",
                             "Headlines - Read",
                             "Language - Read",
                             "Object Selection - Read",
                             "Page Summary Provider - Read",
                             "Page Action Provider - Read",
                             "Printer Management - Read",
                             "Record Link Management - Read",
                             "Recurrence Schedule - Read",
                             "Retention Policy - Read",
                             "Environment Cleanup - Read",
                             "Satisfaction Survey - Read",
                             "System Initialization - Exec",
                             "Security Groups - Read",
                             "Table Information - Read",
                             "Telemetry - Exec",
                             "Tenant License State - Read",
                             "Time Zone Selection - Read",
                             "Translation - Read",
                             "Upgrade Tags - Read",
                             "User Permissions - Read",
                             "User Selection - Read",
                             "Video - Read",
                             "Web Service Management - Read",
                             "Word Templates - Read";
}
