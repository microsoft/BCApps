// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Reflection;

using System.Environment.Configuration;

permissionset 9806 "Field Selection - Read"
{
    Assignable = false;

    Permissions = tabledata Field = r,
                  tabledata "Page Data Personalization" = R;
}