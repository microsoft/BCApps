// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using System.Reflection;
using System.Environment.Configuration;

permissionset 2916 "Page Action Provider - Read"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "All Profile" = r,
                  tabledata "Page Action" = r,
                  tabledata "Page Data Personalization" = R,
                  tabledata "User Personalization" = r; // DotNet NavPageActionALFunctions requires this
}