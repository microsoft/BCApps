// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Document;

/// <summary>
/// Interface for providing document processing utilities for PEPPOL XMLports.
/// Abstracts operations like calculating totals, handling rounding lines, and setting filters.
/// </summary>
interface "PEPPOL Document Processor"
{
    /// <summary>
    /// Calculates and aggregates VAT totals and categories from posted document lines.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="PostedDocLineRecRef">The RecordRef for the posted document lines.</param>
    /// <param name="TempVATAmtLine">Temporary VAT Amount Line to accumulate VAT totals.</param>
    /// <param name="TempVATProductPostingGroup">Temporary VAT Product Posting Group to track categories.</param>
    /// <param name="PEPPOLFormat">The PEPPOL 3.0 format enum value.</param>
    procedure GetTotals(var PostedDocHeaderRecRef: RecordRef; var PostedDocLineRecRef: RecordRef; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary; PEPPOLFormat: Enum "PEPPOL 3.0 Format")

    /// <summary>
    /// Retrieves the invoice rounding line from the posted document, if present.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="TempSalesLineRounding">Temporary Sales Line to store the rounding line details.</param>
    /// <param name="PEPPOLFormat">The PEPPOL 3.0 format enum value.</param>
    procedure GetInvoiceRoundingLine(PostedDocHeaderRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; PEPPOLFormat: Enum "PEPPOL 3.0 Format")

    /// <summary>
    /// Sets filters on posted document lines, excluding the rounding line if present.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="PostedDocLineRecRef">The RecordRef for the posted document lines to set filters on.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record containing the rounding line to exclude.</param>
    procedure SetFilters(var PostedDocHeaderRecRef: RecordRef; var PostedDocLineRecRef: RecordRef; TempSalesLineRounding: Record "Sales Line" temporary)
}
