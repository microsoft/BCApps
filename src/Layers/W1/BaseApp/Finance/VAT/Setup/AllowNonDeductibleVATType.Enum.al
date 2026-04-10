// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// Controls whether non-deductible VAT functionality is allowed for specific VAT posting setup combinations.
/// Used to enable or disable non-deductible VAT calculations on a per-posting-group basis.
/// </summary>
/// <remarks>
/// Usage: Set on VAT Posting Setup to control non-deductible VAT percentage and account assignments.
/// Integration: Works with VAT Setup global enable flag and VAT posting validation processes.
/// </remarks>
enum 6200 "Allow Non-Deductible VAT Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Prohibits non-deductible VAT functionality for this VAT posting setup combination.
    /// </summary>
    value(0; "Do Not Allow") { Caption = 'Do Not Allow'; }
    /// <summary>
    /// Enables non-deductible VAT functionality allowing VAT percentage and account configuration.
    /// </summary>
    value(1; "Allow") { Caption = 'Allow'; }
}