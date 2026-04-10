// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Defines available consolidation processing methods with implementation strategies.
/// Controls which consolidation algorithm is used for business unit data processing.
/// </summary>
enum 404 "Consolidation Method" implements "Consolidation Method"
{
    Extensible = true;
    /// <summary>
    /// Standard consolidation method using the core Consolidate codeunit for processing.
    /// </summary>
    value(0; Default)
    {
        Implementation = "Consolidation Method" = "Default Consolidation Method";
    }
}
