// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Defines document retention period options for managing document lifecycle and compliance requirements.
/// Implements Documents - Retention Period interface to provide extensible retention policy definitions.
/// </summary>
/// <remarks>
/// Extensible enum allowing custom retention period implementations for different document types.
/// Used in document management and compliance frameworks for automated retention policy enforcement.
/// </remarks>
enum 800 "Docs - Retention Period Def." implements "Documents - Retention Period"
{
    Extensible = true;
    /// <summary>
    /// Default retention period implementation using system-defined retention rules.
    /// </summary>
    value(0; Default)
    {
        Caption = 'Default';
        Implementation = "Documents - Retention Period" = "Default Retention Period Def.";
    }
}