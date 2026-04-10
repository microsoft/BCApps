// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Defines the matching algorithms used for comparing related party names during payment application processes.
/// This enum controls how the system attempts to match customer and vendor names found in bank statement data
/// with the names recorded in the Business Central system, enabling automatic payment application.
/// </summary>
#pragma warning disable AL0659
enum 1253 "Pmt. Appl. Related Party Name Matching"
#pragma warning restore AL0659
{
    Extensible = true;

    /// <summary>
    /// Uses string nearness algorithms to find approximate matches between names.
    /// Calculates similarity scores based on character sequences and allows matching names that are similar
    /// but not identical, handling variations in spelling, abbreviations, and extra characters.
    /// </summary>
    value(0; "String Nearness")
    {
        Caption = 'String Nearness';
    }

    /// <summary>
    /// Requires exact character matching but allows for different word orders and permutations.
    /// All words in the names must match exactly, but their sequence can vary, enabling matches
    /// like "John Smith" with "Smith, John" or "ABC Company Ltd" with "Ltd ABC Company".
    /// </summary>
    value(1; "Exact Match with Permutations")
    {
        Caption = 'Exact match with Permutations';
    }

    /// <summary>
    /// Disables related party name matching for automatic payment application.
    /// When selected, the system will not attempt to match based on party names,
    /// relying on other matching criteria such as amounts, references, or manual matching.
    /// </summary>
    value(2; Disabled)
    {
        Caption = 'Disabled';
    }
}
