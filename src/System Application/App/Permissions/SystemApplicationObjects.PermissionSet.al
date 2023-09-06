// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Azure.Identity;
using System.Azure.Storage;
using System.Device;
using System.Security.Encryption;
using System.Visualization;
using System.Feedback;
using System.Privacy;
using System.DateTime;
using System.Integration;
using System.Integration.Excel;
using System.Email;
using System.Text;
using System.Reflection;
using System.Globalization;
using System.Tooling;
using System.Utilities;
using System.DataAdministration;
using System.Integration.Sharepoint;
using System.Security.User;
using System.Media;
using System.Integration.Word;

permissionset 219 "System Application - Objects"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Advanced Settings - Objects",
                             "Azure AD Plan - Objects",
                             "AAD User Management - Objects",
                             "Az. Storage S. Auth. - Objects",
                             "Camera and Media - Objects",
                             "Cryptography Mgt. - Objects",
                             "Cues and KPIs - Objects",
                             "Customer Exp. Survey - Objects",
                             "Data Classification - Objects",
                             "Date-Time Dialog - Objects",
                             "Device - Objects",
                             "Document Sharing - Objects",
                             "Edit in Excel - Objects",
                             "Email - Objects",
                             "Entity Text - Objects",
                             "Extension Management - Objects",
                             "Feature Key - Objects",
                             "Field Selection - Objects",
                             "Geolocation - Objects",
                             "Guided Experience - Objects",
                             "Language - Objects",
                             "Object Selection - Objects",
                             "Page Summary Provider - Obj.",
                             "Page Action Provider - Obj.",
                             "Performance Profiler - Objects",
                             "Permission Sets - Objects",
                             "Printer Management - Objects",
                             "Record Link Management - Obj.",
                             "Recurrence Schedule - Objects",
                             "Retention Policy - Objects",
                             "Satisfaction Survey - Objects",
                             "Security Groups - Objects",
                             "SharePoint API - Objects",
                             "Table Information - Objects",
                             "Translation - Objects",
                             "User Permissions - Objects",
                             "User Selection - Objects",
                             "User Settings - Objects",
                             "Video - Objects",
                             "Web Service Management - Obj.",
                             "Word Templates - Objects";
}
