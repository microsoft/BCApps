// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

/// <summary>
/// Tracks the intercompany processing status of sales documents during intercompany transaction workflow.
/// Controls document state transitions and processing validation in sales-side operations.
/// </summary>
enum 124 "Sales Document IC Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Document created but not yet processed for intercompany transmission.
    /// </summary>
    value(0; "New") { Caption = 'New'; }
    /// <summary>
    /// Document prepared for intercompany transmission but not yet sent.
    /// </summary>
    value(1; "Pending") { Caption = 'Pending'; }
    /// <summary>
    /// Document successfully transmitted to intercompany partner.
    /// </summary>
    value(2; "Sent") { Caption = 'Sent'; }
}
