// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Line Info Provider"
{
    /// <summary>
    /// Gets general line information from the purchase line including invoice line ID, note, quantity, extension amount, and accounting cost.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record.</param>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="InvoiceLineID">Returns the invoice line ID.</param>
    /// <param name="InvoiceLineNote">Returns the invoice line note.</param>
    /// <param name="InvoicedQuantity">Returns the invoiced quantity.</param>
    /// <param name="InvoiceLineExtensionAmount">Returns the invoice line extension amount.</param>
    /// <param name="LineExtensionAmountCurrencyID">Returns the line extension amount currency ID.</param>
    /// <param name="InvoiceLineAccountingCost">Returns the invoice line accounting cost.</param>
    procedure GetLineGeneralInfo(PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)

    /// <summary>
    /// Gets unit code information for the purchase line.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record.</param>
    /// <param name="unitCode">Returns the unit code.</param>
    /// <param name="unitCodeListID">Returns the unit code list ID.</param>
    procedure GetLineUnitCodeInfo(PurchaseLine: Record "Purchase Line"; var unitCode: Text; var unitCodeListID: Text)

    /// <summary>
    /// Gets item information for the purchase line including description, name, item identification codes, and origin country.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record.</param>
    /// <param name="Description">Returns the item description.</param>
    /// <param name="Name">Returns the item name.</param>
    /// <param name="SellersItemIdentificationID">Returns the seller's item identification ID.</param>
    /// <param name="StandardItemIdentificationID">Returns the standard item identification ID.</param>
    /// <param name="StdItemIdIDSchemeID">Returns the standard item ID scheme ID.</param>
    /// <param name="OriginCountryIdCode">Returns the origin country ID code.</param>
    /// <param name="OriginCountryIdCodeListID">Returns the origin country ID code list ID.</param>
    procedure GetLineItemInfo(PurchaseLine: Record "Purchase Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)

    /// <summary>
    /// Gets classified tax category information for the purchase line item.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record.</param>
    /// <param name="ClassifiedTaxCategoryID">Returns the classified tax category ID.</param>
    /// <param name="ItemSchemeID">Returns the item scheme ID.</param>
    /// <param name="InvoiceLineTaxPercent">Returns the invoice line tax percentage.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Returns the classified tax category scheme ID.</param>
    procedure GetLineItemClassifiedTaxCategory(PurchaseLine: Record "Purchase Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)

    /// <summary>
    /// Gets price information for the purchase line.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line record.</param>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="InvoiceLinePriceAmount">Returns the invoice line price amount.</param>
    /// <param name="InvLinePriceAmountCurrencyID">Returns the invoice line price amount currency ID.</param>
    /// <param name="BaseQuantity">Returns the base quantity for price calculation.</param>
    /// <param name="UnitCode">Returns the unit code for the base quantity.</param>
    procedure GetLinePriceInfo(PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var InvoiceLinePriceAmount: Text; var InvLinePriceAmountCurrencyID: Text; var BaseQuantity: Text; var UnitCode: Text)
}
