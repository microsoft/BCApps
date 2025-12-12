// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

/// <summary>
/// Provides iteration over posted PEPPOL documents needed during export.
/// Exposes methods to find the next posted document header and line records,
/// and transfer their fields to working Sales Header and Sales Line buffers.
/// </summary>
interface "PEPPOL Posted Document Iterator"
{
    /// <summary>
    /// Gets the next posted document header record and transfers its fields to a Sales Header buffer.
    /// </summary>
    /// <param name="PostedRecRef">The RecordRef for the posted document header (e.g., Sales Invoice Header or Sales Cr.Memo Header).</param>
    /// <param name="Position">The position indicator: 1 to find the first record, otherwise finds the next record.</param>
    /// <param name="SalesHeader">Return value: The Sales Header record populated with fields from the posted document.</param>
    /// <returns>True if a record was found; otherwise, false.</returns>
    procedure GetNextPostedHeaderAsSalesHeader(var PostedRecRef: RecordRef; var SalesHeader: Record "Sales Header") Found: Boolean;

    /// <summary>
    /// Gets the next posted document line record and transfers its fields to a Sales Line buffer.
    /// </summary>
    /// <param name="PostedLineRecRef">The RecordRef for the posted document line (e.g., Sales Invoice Line or Sales Cr.Memo Line).</param>
    /// <param name="Position">The position indicator: 1 to find the first record, otherwise finds the next record.</param>
    /// <param name="SalesLine">Return value: The Sales Line record populated with fields from the posted document line.</param>
    /// <returns>True if a record was found; otherwise, false.</returns>
    procedure GetNextPostedLineAsSalesLine(var PostedLineRecRef: RecordRef; var SalesLine: Record "Sales Line") Found: Boolean
}
