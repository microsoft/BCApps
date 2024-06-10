// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

permissionset 1921 "Performance Profiler - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Sampling Performance Profiler" = X,
                  codeunit "Scheduled Perf. Profiler" = X,
                  page "Performance Profiler" = X,
                  page "Perf. Profiler Schedules List" = X,
                  page "Perf. Profiler Schedule Card" = X,
                  page "Performance Profiles" = X,
                  tabledata "Performance Profile Scheduler" = Rimd,
                  tabledata "Performance Profiles" = R;
}
