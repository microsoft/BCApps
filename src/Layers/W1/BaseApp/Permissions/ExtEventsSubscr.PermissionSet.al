// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Integration;

permissionset 5264 "Ext. Events - Subscr"
{
    Caption = 'External Events - Subscribe';
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Ext. Events - Objects";

    Permissions = tabledata "External Event Activity Log" = RI,
                  tabledata "External Event Subscription" = RIMD,
                  tabledata "Ext. Business Event Definition" = R;
}
