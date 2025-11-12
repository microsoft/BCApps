// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Maintenance;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.Item;

permissionset 4842 "Service Management - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'SM periodic activities';

    Permissions = tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata "Service Document Log" = R,
                  tabledata "Service Email Queue" = RIMD,
                  tabledata "Service Item Log" = R;
}
