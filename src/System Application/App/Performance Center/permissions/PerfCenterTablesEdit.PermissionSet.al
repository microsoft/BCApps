// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

permissionset 8433 "Perf. Center Tables - Edit"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Perf. Center Tables - View";

    Permissions = tabledata "Performance Analysis" = IMD,
                  tabledata "Performance Analysis Line" = IMD,
                  tabledata "Perf. Analysis LLM Log" = IMD;
}
