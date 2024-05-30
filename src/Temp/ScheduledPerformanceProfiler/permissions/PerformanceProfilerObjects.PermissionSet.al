// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

permissionset 1922 "Sched Perf Profiler - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = page "Perf. Profiler Schedules List" = X,
                  page "Perf. Profiler Schedules Card" = X,
                  page "Performance Profiles" = X;
}
