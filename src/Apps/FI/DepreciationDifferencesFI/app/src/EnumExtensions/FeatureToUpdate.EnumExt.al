#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Environment.Configuration;

enumextension 13474 "Depr Diff FI Feature To Update" extends "Feature To Update"
{
    value(13474; DepreciationDifferencesFI)
    {
        Implementation = "Feature Data Update" = "Dep Diff FI Feature Data Update";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Depreciation Differences FI will be enabled by default in version 32.0.';
        ObsoleteTag = '29.0';
    }
}
#endif
