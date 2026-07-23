#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Environment.Configuration;

enumextension 13477 "Feature DeprDifference FI" extends "Feature To Update"
{
    value(13477; DeprDifferenceFI)
    {
        Implementation = "Feature Data Update" = "Feature Depr. Difference FI";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Posting Depreciation Differences will be enabled by default in version 32.0.';
        ObsoleteTag = '29.0';
    }
}
#endif
