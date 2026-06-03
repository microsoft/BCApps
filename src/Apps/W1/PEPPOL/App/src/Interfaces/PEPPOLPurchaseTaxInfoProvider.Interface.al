// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Tax Info Provider"
{
    /// <summary>
    /// Gets totals and calculates VAT amount lines from the purchase line information.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record to calculate totals from.</param>
    /// <param name="VATAmtLine">Returns the calculated VAT amount line totals.</param>
    procedure GetTaxTotals(PurchaseLine: Record "Purchase Line"; var VATAmtLine: Record "VAT Amount Line")

    /// <summary>
    /// Gets tax categories from the purchase line and populates VAT product posting group category information.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record containing tax category information.</param>
    /// <param name="VATProductPostingGroupCategory">Returns the VAT product posting group category information.</param>
    procedure GetTaxCategories(PurchaseLine: Record "Purchase Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
}
