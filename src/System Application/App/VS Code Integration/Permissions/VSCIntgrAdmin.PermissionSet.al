// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Tooling;
using System.Reflection;

permissionset 8035 "VSC Intgr. - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'VS Code Integration - Admin';

    IncludedPermissionSets = "Extension Management - View";

    Permissions = tabledata AllObjWithCaption = Rimd,
                  tabledata "Application Object Metadata" = Rimd, // r needed for check CanInteractWithSourceCode
                  tabledata "Extension Execution Info" = Rimd,
                  tabledata "Page Info And Fields" = Rimd,
                  tabledata "Published Application" = Rimd;
}