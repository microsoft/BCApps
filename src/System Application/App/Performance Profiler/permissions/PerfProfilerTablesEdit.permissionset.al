// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

permissionset 1923 "Perf. Profiler Tables - Edit"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Performance Profile Scheduler" = imd;
    IncludedPermissionSets = "Perf. Profiler Tables - View";
}
