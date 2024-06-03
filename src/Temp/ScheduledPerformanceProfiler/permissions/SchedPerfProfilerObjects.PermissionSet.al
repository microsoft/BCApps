// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

permissionset 1922 "Sched Perf Profiler - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
                  tabledata "Performance Profile Scheduler" = RIMD,
                  tabledata "Performance Profiles" = R,
                  page "Perf. Profiler Schedules List" = X,
                  page "Perf Profiler Schedule Card" = X,
                  page "Performance Profiles" = X;
}
