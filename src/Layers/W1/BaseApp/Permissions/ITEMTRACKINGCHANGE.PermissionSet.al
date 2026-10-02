// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Inventory.Tracking;

permissionset 6534 "ITEM TRACKING CHANGE"
{
    Access = Public;
    Assignable = true;
    Caption = 'Change Item Tracking Code';

    Permissions = tabledata "Item Tracking Code Change Log" = RI;
}
