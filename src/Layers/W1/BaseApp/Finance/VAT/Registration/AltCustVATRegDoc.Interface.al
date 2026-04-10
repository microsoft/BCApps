// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// The interfaces provides methods to handle the alternative customer VAT registration in the document.
/// </summary>
interface "Alt. Cust. VAT Reg. Doc."
{
    Access = Public;

    /// <summary>
    /// Initializes the VAT registration data taken from the alternative customer registration in the sales header.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record</param>
    /// <param name="xSalesHeader">The previous version of the record</param>
    procedure Init(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")

    /// <summary>
    /// Copies the VAT registration data from the customer to the sales header.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record</param>
    /// <param name="xSalesHeader">The previous version of the record</param>
    procedure CopyFromCustomer(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")

    /// <summary>
    /// Updates the VAT registration data when the Ship-to Country/Region Code is changed in the sales header.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record</param>
    /// <param name="xSalesHeader">The previous version of the record</param>
    procedure UpdateSetupOnShipToCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")

    /// <summary>
    /// Updates the VAT registration data when the VAT Country/Region Code is changed in the sales header.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record</param>
    /// <param name="xSalesHeader">The previous version of the record</param>
    procedure UpdateSetupOnVATCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")

    /// <summary>
    /// Updates the VAT registration data when the Bill-to Customer is changed in the sales header.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record</param>
    /// <param name="BillToCustomer">The bill-to customer of the sales header</param>
    /// <param name="xSalesHeader">The previous version of the record</param>
    procedure UpdateSetupOnBillToCustomerChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; BillToCustomer: Record Customer)
}