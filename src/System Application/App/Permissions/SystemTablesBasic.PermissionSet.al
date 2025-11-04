// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Environment;
using System.Environment.Configuration;
#if not CLEAN28
using System.Feedback;
#endif
using System.Integration;
using System.IO;
using System.Reflection;
using System.Security.Authentication;
using System.Security.User;
using System.Tooling;

permissionset 66 "System Tables - Basic"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Basic User (All Inclusive)';

    IncludedPermissionSets = "Company - Read",
                             "Media - View",
                             "Metadata - Read",
                             "Permissions & Licenses - Read",
                             "Power BI - Read",
                             "Reporting - Edit",
#if not CLEAN28
                             "Satisfaction Survey - View",
#endif
                             "Session - Read",
                             "System Execute - Basic",
                             "User Personalization - Edit",
                             "User Selection - Read",
                             "Webhook - Edit",
                             "Data Analysis - Exec",
                             "Add Related Fields",
                             "Perf. Profiler Tables - Edit";

    Permissions = tabledata "Add-in" = R,
                  tabledata "Aggregate Permission Set" = Rimd,
                  tabledata "All Profile Page Metadata" = Rimd,
                  tabledata "Code Coverage" = Rimd,
                  tabledata "Configuration Package File" = RIMD,
                  tabledata "Document Service" = R,
                  tabledata "Document Service Scenario" = R,
                  tabledata Drive = Rimd,
                  tabledata "Event Subscription" = Rimd,
                  tabledata "External Event Activity Log" = I,
                  tabledata "External Event Log Entry" = I,
                  tabledata Field = Rimd,
                  tabledata File = Rimd,
                  tabledata "Object Options" = Rimd,
                  tabledata "OData Edm Type" = Rimd,
                  tabledata "Record Link" = RIMD,
                  tabledata "Scheduled Task" = R,
                  tabledata "Send-To Program" = RIMD,
                  tabledata Session = Rimd,
                  tabledata "Server Instance" = Rimd,
                  tabledata "SID - Account ID" = Rimd,
                  tabledata "Signup Context" = R,
                  tabledata "Style Sheet" = RIMD,
                  tabledata "System Object" = Rimd,
                  tabledata "Tenant Profile Page Metadata" = Rimd,
                  tabledata "Token Cache" = Rimd;
}