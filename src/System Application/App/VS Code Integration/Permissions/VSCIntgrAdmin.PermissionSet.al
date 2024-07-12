// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using System.Apps;
using System.Tooling;
using System.Reflection;

permissionset 8335 "VSC Intgr. - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'VS Code Integration - Admin';

    Permissions = tabledata AllObjWithCaption = R,
                  tabledata "Application Object Metadata" = R, // r needed for check CanInteractWithSourceCode
                  tabledata "Extension Execution Info" = R,
                  tabledata "Page Info And Fields" = R,
                  tabledata "Published Application" = R;
}