// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Security.AccessControl;

permissionsetextension 13485 "Dep Diff FI - Objects" extends "D365 BASIC"
{
    Permissions =
        tabledata "Depr. Diff. Posting Buffer FI" = RIMD,
        table "Depr. Diff. Posting Buffer FI" = X,
        report "Calc. and Post Depr. Diff. FI" = X,
        codeunit "Dep Diff FI Subscribers" = X,
#if not CLEAN29
        codeunit "Dep Diff FI Feature" = X,
        codeunit "Dep Diff FI Feature Data Upd." = X,
#endif
#if CLEAN29
        codeunit "Upgrade Depreciation Diff. FI" = X,
#endif
        codeunit "Dep Diff FI Upgrade Tag" = X;
}
