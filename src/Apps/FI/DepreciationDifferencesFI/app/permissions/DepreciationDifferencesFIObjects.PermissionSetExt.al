// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

permissionsetextension 13485 "Dep Diff FI - Objects" extends "D365 BASIC"
{
    Permissions =
        tabledata "Depr. Diff. Posting Buffer" = RIMD,
        table "Depr. Diff. Posting Buffer" = X,
        report "Calc. and Post Depr. Diff." = X,
        codeunit "Depreciation Differences FI Subscribers" = X,
#if not CLEAN29
        codeunit "Depreciation Differences FI Feature" = X,
        codeunit "Dep Diff FI Feature Data Update" = X,
#endif
#if CLEAN29
        codeunit "Upgrade Depreciation Diff. FI" = X,
#endif
        codeunit "Dep Diff FI Upgrade Tag" = X;
}
