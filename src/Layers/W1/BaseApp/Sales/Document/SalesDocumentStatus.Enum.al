// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the workflow status values for sales documents.
/// </summary>
enum 3612 "Sales Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the sales document is open and can be edited.
    /// </summary>
    value(0; Open) { Caption = 'Open'; }
    /// <summary>
    /// Indicates that the sales document has been released for further processing.
    /// </summary>
    value(1; Released) { Caption = 'Released'; }
    /// <summary>
    /// Indicates that the sales document is awaiting approval in a workflow.
    /// </summary>
    value(2; "Pending Approval") { Caption = 'Pending Approval'; }
    /// <summary>
    /// Indicates that the sales document is awaiting prepayment before processing can continue.
    /// </summary>
    value(3; "Pending Prepayment") { Caption = 'Pending Prepayment'; }
}
