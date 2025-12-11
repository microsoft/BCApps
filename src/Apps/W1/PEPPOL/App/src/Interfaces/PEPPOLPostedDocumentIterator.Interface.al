// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.History;

/// <summary>
/// Provides iteration over posted PEPPOL documents needed during export.
/// Exposes methods to find the next posted document header and line records,
/// and transfer their fields to working Sales Header and Sales Line buffers.
/// </summary>
interface "PEPPOL Posted Document Iterator"
{
    /// <summary>
    /// Finds the next posted document header record and transfers its fields to a Sales Header buffer.
    /// </summary>
    /// <param name="PostedRec">The RecordRef for the posted document header (e.g., Sales Invoice Header or Sales Cr.Memo Header).</param>
    /// <param name="SalesHeader">Return value: The Sales Header record populated with fields from the posted document.</param>
    /// <param name="Position">The position indicator: 1 to find the first record, otherwise finds the next record.</param>
    /// <returns>True if a record was found; otherwise, false.</returns>
    procedure FindNextPostedRec(var PostedRec: RecordRef; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean;

    /// <summary>
    /// Finds the next posted document line record and transfers its fields to a Sales Line buffer.
    /// </summary>
    /// <param name="PostedRecLine">The RecordRef for the posted document line (e.g., Sales Invoice Line or Sales Cr.Memo Line).</param>
    /// <param name="SalesLine">Return value: The Sales Line record populated with fields from the posted document line.</param>
    /// <param name="Position">The position indicator: 1 to find the first record, otherwise finds the next record.</param>
    /// <returns>True if a record was found; otherwise, false.</returns>
    procedure FindNextPostedLineRec(var PostedRecLine: RecordRef; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
}
