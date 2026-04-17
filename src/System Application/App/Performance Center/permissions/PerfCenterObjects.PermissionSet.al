// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

permissionset 5498 "Perf. Center - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Perf. Analysis Mgt." = X,
                  codeunit "Perf. Analysis Monitor" = X,
                  page "Performance Center" = X,
                  page "Perf. Analysis Wizard" = X,
                  page "Perf. Analysis List" = X,
                  page "Perf. Analysis List Part" = X,
                  page "Perf. Analysis Card" = X,
                  page "Perf. Analysis Profile List" = X,
                  page "Perf. Analysis Signals" = X,
                  page "Perf. Analysis Chat" = X,
                  page "Perf. Analysis Chat Req. Stub" = X;
}
