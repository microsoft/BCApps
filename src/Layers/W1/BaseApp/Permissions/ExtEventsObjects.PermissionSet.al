// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Integration;

permissionset 5263 "Ext. Events - Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = table "External Event Activity Log" = X,
                  table "External Event Subscription" = X,
                  table "External Event Log Entry" = X,
                  table "External Event Notification" = X,
                  table "Ext. Business Event Definition" = X;
}
