// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 6426 "Prepare Sales E-Doc. Draft" implements IProcessStructuredDataSales
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Sales Draft";

    /// <summary>
    /// Resolves the customer and sales lines for the staging draft, then returns the E-Document type.
    /// </summary>
    /// <param name="EDocument">The E-Document record being processed.</param>
    /// <param name="EDocImportParameters">Import parameters that carry processing customizations.</param>
    /// <returns>"Sales Order" always, regardless of the OrderTypeCode in the staging data.</returns>
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        exit("E-Document Type"::"Sales Order");
    end;

    /// <summary>
    /// Opens the draft review page for the sales order E-Document.
    /// </summary>
    /// <param name="EDocument">The E-Document record whose draft page should be opened.</param>
    procedure OpenDraftPage(var EDocument: Record "E-Document")
    var
        EDocumentSalesHeader: Record "E-Document Sales Header";
        EDocSalesDraft: Page "E-Document Sales Draft";
    begin
        if EDocumentSalesHeader.Get(EDocument."Entry No") then begin
            EDocSalesDraft.SetRecord(EDocumentSalesHeader);
            EDocSalesDraft.Run();
        end;
    end;

    /// <summary>
    /// Deletes the sales staging header and all associated line records for the given E-Document.
    /// </summary>
    /// <param name="EDocument">The E-Document record being cleaned up.</param>
    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.CleanUpDraft(EDocument);
    end;

    /// <summary>
    /// Not applicable for inbound sales orders; customer resolution uses ICustomerProvider instead.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="Customizations">Processing customizations that may override resolution.</param>
    /// <returns>An empty Vendor record.</returns>
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    begin
        Clear(Vendor);
        exit(Vendor);
    end;

    /// <summary>
    /// Returns the resolved customer for the sales order E-Document.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="Customizations">Processing customizations that may override customer resolution.</param>
    /// <returns>The resolved Customer record, or an empty record if unresolved.</returns>
    procedure GetCustomer(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Customer: Record Customer
    begin
        Customer := PrepareDraftHelper.GetCustomer(EDocument, Customizations);
    end;
}
