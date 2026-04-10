// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

#pragma warning disable AL0659
/// <summary>
/// Defines the posting type requirements for default dimension values.
/// Controls how dimension values are validated and enforced during posting operations.
/// </summary>
enum 353 "Default Dimension Value Posting Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No specific dimension value posting requirement.
    /// Default behavior without special validation or enforcement rules.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// A dimension value must be specified and cannot be blank.
    /// Enforces mandatory dimension value entry during transaction posting.
    /// </summary>
    value(1; "Code Mandatory") { Caption = 'Code Mandatory'; }
    /// <summary>
    /// The dimension value must match the default dimension value exactly.
    /// Prevents users from changing the predefined dimension value during posting.
    /// </summary>
    value(2; "Same Code") { Caption = 'Same Code'; }
    /// <summary>
    /// No dimension value is allowed for this dimension.
    /// Blocks dimension value entry to prevent unwanted dimension analysis.
    /// </summary>
    value(3; "No Code") { Caption = 'No Code'; }
}
