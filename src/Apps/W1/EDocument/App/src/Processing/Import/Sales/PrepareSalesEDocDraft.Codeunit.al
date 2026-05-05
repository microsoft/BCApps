// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;

codeunit 50000 "Prepare Sales E-Doc. Draft" implements IProcessStructuredData
{
    Access = Internal;

    /// <summary>
    /// Returns the E-Document type for a sales order. No Business Central entity resolution is performed
    /// because inbound sales orders do not require mapping to purchase-side staging data.
    /// </summary>
    /// <param name="EDocument">The E-Document record being processed.</param>
    /// <param name="EDocImportParameters">Import parameters that carry processing customizations.</param>
    /// <returns>The resolved E-Document type, always "Sales Order" for this implementation.</returns>
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        exit("E-Document Type"::"Sales Order");
    end;

    /// <summary>
    /// Opens the draft page for the E-Document. Not implemented for sales orders.
    /// </summary>
    /// <param name="EDocument">The E-Document record whose draft page should be opened.</param>
    procedure OpenDraftPage(var EDocument: Record "E-Document")
    begin
    end;

    /// <summary>
    /// Cleans up any records created during draft processing. No cleanup is required for sales orders.
    /// </summary>
    /// <param name="EDocument">The E-Document record being cleaned up.</param>
    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
    end;

    /// <summary>
    /// Returns the vendor for the E-Document. Not applicable for inbound sales orders,
    /// which represent a customer's order rather than a vendor transaction.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="Customizations">Processing customizations that may override vendor resolution.</param>
    /// <returns>An empty Vendor record.</returns>
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    begin
    end;
}
