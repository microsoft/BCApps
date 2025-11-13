// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;

/// <summary>
/// Interface for managing PEPPOL 3.0 export operations.
/// Provides methods for initializing export data, iterating through records and lines,
/// and calculating totals for PEPPOL document generation.
/// </summary>
interface "PEPPOL30 Export Management"
{
    /// <summary>
    /// Initializes the export management with the provided record reference and associated data.
    /// Sets up the context for PEPPOL document export operations.
    /// </summary>
    /// <param name="RecRef">The record reference to the source document (e.g., Sales Invoice Header, Sales Cr.Memo Header).</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record for handling rounding adjustments.</param>
    /// <param name="DocumentAttachments">Document attachments record for handling file attachments.</param>
    procedure Init(RecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment");

    /// <summary>
    /// Finds and moves to the next document record in the export sequence.
    /// Used for iterating through multiple documents during batch export operations.
    /// </summary>
    /// <param name="Position">The position/index for finding the next record in the sequence.</param>
    /// <param name="EDocumentFormat">The electronic document format being used for export.</param>
    /// <returns>True if a next record was found and positioned, false if no more records exist.</returns>
    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format"): Boolean

    /// <summary>
    /// Finds and moves to the next line record within the current document.
    /// Used for iterating through document lines during export processing.
    /// </summary>
    /// <param name="Position">The position/index for finding the next line record in the sequence.</param>
    /// <param name="EDocumentFormat">The electronic document format being used for export.</param>
    /// <returns>True if a next line record was found and positioned, false if no more lines exist.</returns>
    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format"): Boolean

    procedure GetRec(): Variant

    procedure GetLineRec(): Variant

/// <summary>
/// Calculates and retrieves totals for VAT amounts and VAT product posting groups.
/// Populates temporary records with calculated totals required for PEPPOL document generation.
/// </summary>
/// <param name="TempVATAmtLine">Returns temporary VAT amount line records with calculated VAT totals by tax rate.</param>
/// <param name="TempVATProductPostingGroup">Returns temporary VAT product posting group records with tax category information.</param>
#if not CLEAN25
#pragma warning disable AL0432
#endif
procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
#if not CLEAN25
#pragma warning restore AL0432
#endif
}