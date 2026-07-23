#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using System.Environment.Configuration;

enumextension 5869 "Feature - Accelerated Depr." extends "Feature To Update"
{
    value(5865; AcceleratedDepreciation)
    {
        Implementation = "Feature Data Update" = "Accelerated Depr. Feature";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Accelerated depreciation will be enabled by default in version 31.0.';
        ObsoleteTag = '29.0';
    }
}
#endif