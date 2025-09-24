// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;

/// <summary>
/// Interface for PEPPOL 3.0 sales export operations.
/// Provides methods for calculating VAT totals and handling sales-specific export functionality.
/// </summary>
interface "PEPPOL30 Sales Export"
{
    /// <summary>
    /// Calculates and retrieves VAT totals for a sales document.
    /// </summary>
    /// <param name="DocumentNo">The document number to calculate totals for.</param>
    /// <param name="TempVATAmtLine">Temporary VAT amount line record to store calculated totals.</param>
    /// <param name="TempVATProductPostingGroup">Temporary VAT product posting group record.</param>
    procedure GetTotals(DocumentNo: Code[20]; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
}