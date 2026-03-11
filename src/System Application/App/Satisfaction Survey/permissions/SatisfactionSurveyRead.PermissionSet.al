#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;

permissionset 1432 "Satisfaction Survey - Read"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Add-in" = r,
#pragma warning disable AL0432
                  tabledata "Net Promoter Score" = r,
                  tabledata "Net Promoter Score Setup" = r,
#pragma warning restore AL0432
                  tabledata "User Personalization" = r,
                  tabledata "User Property" = r;
}
#endif