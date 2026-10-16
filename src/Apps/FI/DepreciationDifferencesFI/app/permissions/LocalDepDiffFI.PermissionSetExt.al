// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Security.AccessControl;

permissionsetextension 13484 "LOCAL - Dep Diff FI" extends "LOCAL"
{
    Permissions =
        tabledata "Depr. Diff. Posting Buffer FI" = RIMD,
        table "Depr. Diff. Posting Buffer FI" = X;
}
