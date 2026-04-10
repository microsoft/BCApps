// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

/// <summary>
/// Specifies the direction of intercompany transactions for processing and mapping purposes.
/// Controls transaction flow between companies in intercompany operations.
/// </summary>
enum 129 "IC Direction Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Transactions sent from current company to intercompany partners.
    /// </summary>
    value(0; "Outgoing") { Caption = 'Outgoing'; }
    /// <summary>
    /// Transactions received from intercompany partners into current company.
    /// </summary>
    value(1; "Incoming") { Caption = 'Incoming'; }
}
