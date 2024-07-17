// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

permissionset 1922 "Perf. Profiler Tables - View"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Performance Profile Scheduler" = R,
              tabledata "Performance Profiles" = R;
}
