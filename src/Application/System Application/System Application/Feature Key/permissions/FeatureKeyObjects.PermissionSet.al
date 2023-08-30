// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.DateTime;

permissionset 2609 "Feature Key - Objects"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Date-Time Dialog - Objects";

    Permissions = Codeunit "Feature Data Error Handler" = X,
                  Codeunit "Feature Management Facade" = X,
                  Codeunit "Update Feature Data" = X,
                  Page "Feature Management" = X,
                  Page "Schedule Feature Data Update" = X,
#if not CLEAN23
#pragma warning disable AL0432

                  Page "Upcoming Changes Factbox" = X,
#pragma warning restore AL0432
#endif
                  Table "Feature Data Update Status" = X;
}
