// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

interface "PEPPOL Line Info Provider"
{
    /// <summary>
    /// Gets line general information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLineID">Return value: Invoice line ID.</param>
    /// <param name="InvoiceLineNote">Return value: Invoice line note.</param>
    /// <param name="InvoicedQuantity">Return value: Invoiced quantity.</param>
    /// <param name="InvoiceLineExtensionAmount">Return value: Invoice line extension amount.</param>
    /// <param name="LineExtensionAmountCurrencyID">Return value: Line extension amount currency ID.</param>
    /// <param name="InvoiceLineAccountingCost">Return value: Invoice line accounting cost.</param>
    procedure GetLineGeneralInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineID: Text; var InvoiceLineNote: Text; var InvoicedQuantity: Text; var InvoiceLineExtensionAmount: Text; var LineExtensionAmountCurrencyID: Text; var InvoiceLineAccountingCost: Text)

    /// <summary>
    /// Gets line unit code information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="unitCode">Return value: Unit code.</param>
    /// <param name="unitCodeListID">Return value: Unit code list ID.</param>
    procedure GetLineUnitCodeInfo(SalesLine: Record "Sales Line"; var UnitCode: Text; var UnitCodeListID: Text)

    /// <summary>
    /// Gets line invoice period information for PEPPOL documents.
    /// </summary>
    /// <param name="InvLineInvoicePeriodStartDate">Return value: Invoice line invoice period start date.</param>
    /// <param name="InvLineInvoicePeriodEndDate">Return value: Invoice line invoice period end date.</param>
    procedure GetLineInvoicePeriodInfo(var InvLineInvoicePeriodStartDate: Text; var InvLineInvoicePeriodEndDate: Text)

    /// <summary>
    /// Gets line delivery information for PEPPOL documents.
    /// </summary>
    /// <param name="InvoiceLineActualDeliveryDate">Return value: Invoice line actual delivery date.</param>
    /// <param name="InvoiceLineDeliveryID">Return value: Invoice line delivery ID.</param>
    /// <param name="InvoiceLineDeliveryIDSchemeID">Return value: Invoice line delivery ID scheme ID.</param>
    procedure GetLineDeliveryInfo(var InvoiceLineActualDeliveryDate: Text; var InvoiceLineDeliveryID: Text; var InvoiceLineDeliveryIDSchemeID: Text)

    /// <summary>
    /// Gets line delivery postal address information for PEPPOL documents.
    /// </summary>
    /// <param name="InvoiceLineDeliveryStreetName">Return value: Invoice line delivery street name.</param>
    /// <param name="InvLineDeliveryAddStreetName">Return value: Invoice line delivery additional street name.</param>
    /// <param name="InvoiceLineDeliveryCityName">Return value: Invoice line delivery city name.</param>
    /// <param name="InvoiceLineDeliveryPostalZone">Return value: Invoice line delivery postal zone.</param>
    /// <param name="InvLnDeliveryCountrySubentity">Return value: Invoice line delivery country subentity.</param>
    /// <param name="InvLnDeliveryCountryIdCode">Return value: Invoice line delivery country ID code.</param>
    /// <param name="InvLineDeliveryCountryListID">Return value: Invoice line delivery country list ID.</param>
    procedure GetLineDeliveryPostalAddr(var InvoiceLineDeliveryStreetName: Text; var InvLineDeliveryAddStreetName: Text; var InvoiceLineDeliveryCityName: Text; var InvoiceLineDeliveryPostalZone: Text; var InvLnDeliveryCountrySubentity: Text; var InvLnDeliveryCountryIdCode: Text; var InvLineDeliveryCountryListID: Text)

    /// <summary>
    /// Gets line allowance charge information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvLnAllowanceChargeIndicator">Return value: Invoice line allowance charge indicator.</param>
    /// <param name="InvLnAllowanceChargeReason">Return value: Invoice line allowance charge reason.</param>
    /// <param name="InvLnAllowanceChargeAmount">Return value: Invoice line allowance charge amount.</param>
    /// <param name="InvLnAllowanceChargeAmtCurrID">Return value: Invoice line allowance charge amount currency ID.</param>
    procedure GetLineAllowanceChargeInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvLnAllowanceChargeIndicator: Text; var InvLnAllowanceChargeReason: Text; var InvLnAllowanceChargeAmount: Text; var InvLnAllowanceChargeAmtCurrID: Text)

    /// <summary>
    /// Gets line tax total information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLineTaxAmount">Return value: Invoice line tax amount.</param>
    /// <param name="currencyID">Return value: Currency ID.</param>
    procedure GetLineTaxTotal(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLineTaxAmount: Text; var currencyID: Text)

    /// <summary>
    /// Gets line item information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="Description">Return value: Item description.</param>
    /// <param name="Name">Return value: Item name.</param>
    /// <param name="SellersItemIdentificationID">Return value: Seller's item identification ID.</param>
    /// <param name="StandardItemIdentificationID">Return value: Standard item identification ID.</param>
    /// <param name="StdItemIdIDSchemeID">Return value: Standard item ID scheme ID.</param>
    /// <param name="OriginCountryIdCode">Return value: Origin country ID code.</param>
    /// <param name="OriginCountryIdCodeListID">Return value: Origin country ID code list ID.</param>
    procedure GetLineItemInfo(SalesLine: Record "Sales Line"; var Description: Text; var Name: Text; var SellersItemIdentificationID: Text; var StandardItemIdentificationID: Text; var StdItemIdIDSchemeID: Text; var OriginCountryIdCode: Text; var OriginCountryIdCodeListID: Text)

    /// <summary>
    /// Gets line item commodity classification information for PEPPOL documents.
    /// </summary>
    /// <param name="CommodityCode">Return value: Commodity code.</param>
    /// <param name="CommodityCodeListID">Return value: Commodity code list ID.</param>
    /// <param name="ItemClassificationCode">Return value: Item classification code.</param>
    /// <param name="ItemClassificationCodeListID">Return value: Item classification code list ID.</param>
    procedure GetLineItemCommodityClassificationInfo(var CommodityCode: Text; var CommodityCodeListID: Text; var ItemClassificationCode: Text; var ItemClassificationCodeListID: Text)

    /// <summary>
    /// Gets line item classified tax category information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="ClassifiedTaxCategoryID">Return value: Classified tax category ID.</param>
    /// <param name="ItemSchemeID">Return value: Item scheme ID.</param>
    /// <param name="InvoiceLineTaxPercent">Return value: Invoice line tax percent.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Return value: Classified tax category scheme ID.</param>
    procedure GetLineItemClassifiedTaxCategory(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)

    /// <summary>
    /// Gets line item classified tax category information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="ClassifiedTaxCategoryID">Return value: Classified tax category ID.</param>
    /// <param name="ItemSchemeID">Return value: Item scheme ID.</param>
    /// <param name="InvoiceLineTaxPercent">Return value: Invoice line tax percent.</param>
    /// <param name="ClassifiedTaxCategorySchemeID">Return value: Classified tax category scheme ID.</param>
    procedure GetLineItemClassifiedTaxCategoryBIS(SalesLine: Record "Sales Line"; var ClassifiedTaxCategoryID: Text; var ItemSchemeID: Text; var InvoiceLineTaxPercent: Text; var ClassifiedTaxCategorySchemeID: Text)

    /// <summary>
    /// Gets line additional item property information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="AdditionalItemPropertyName">Return value: Additional item property name.</param>
    /// <param name="AdditionalItemPropertyValue">Return value: Additional item property value.</param>
    procedure GetLineAdditionalItemPropertyInfo(SalesLine: Record "Sales Line"; var AdditionalItemPropertyName: Text; var AdditionalItemPropertyValue: Text)

    /// <summary>
    /// Gets line price information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="InvoiceLinePriceAmount">Return value: Invoice line price amount.</param>
    /// <param name="InvLinePriceAmountCurrencyID">Return value: Invoice line price amount currency ID.</param>
    /// <param name="BaseQuantity">Return value: Base quantity.</param>
    /// <param name="UnitCode">Return value: Unit code.</param>
    procedure GetLinePriceInfo(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var InvoiceLinePriceAmount: Text; var InvLinePriceAmountCurrencyID: Text; var BaseQuantity: Text; var UnitCode: Text)

    /// <summary>
    /// Gets line price allowance charge information for PEPPOL documents.
    /// </summary>
    /// <param name="PriceChargeIndicator">Return value: Price charge indicator.</param>
    /// <param name="PriceAllowanceChargeAmount">Return value: Price allowance charge amount.</param>
    /// <param name="PriceAllowanceAmountCurrencyID">Return value: Price allowance amount currency ID.</param>
    /// <param name="PriceAllowanceChargeBaseAmount">Return value: Price allowance charge base amount.</param>
    /// <param name="PriceAllowChargeBaseAmtCurrID">Return value: Price allowance charge base amount currency ID.</param>
    procedure GetLinePriceAllowanceChargeInfo(var PriceChargeIndicator: Text; var PriceAllowanceChargeAmount: Text; var PriceAllowanceAmountCurrencyID: Text; var PriceAllowanceChargeBaseAmount: Text; var PriceAllowChargeBaseAmtCurrID: Text)
}