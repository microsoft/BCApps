// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Manages sales pricing including prices, discounts, price lists, and price calculation for sales transactions.
/// </summary>
/// <remarks>
/// <para><b>Key Capabilities:</b></para>
/// <list type="bullet">
///   <item>Sales price management for items by customer, customer group, or campaign</item>
///   <item>Line discount configuration by item or item discount group</item>
///   <item>Invoice discount setup based on minimum amounts</item>
///   <item>Price list management with validity periods and currency support</item>
///   <item>Price worksheet for batch price updates and suggestions</item>
///   <item>Price calculation logic for sales documents</item>
/// </list>
/// <para><b>Core Subsystems:</b></para>
/// <list type="bullet">
///   <item><c>Sales Price</c> - Item prices by sales type and customer</item>
///   <item><c>Sales Line Discount</c> - Line discounts by item or discount group</item>
///   <item><c>Customer Price Group</c> - Price grouping for customers</item>
///   <item><c>Customer Discount Group</c> - Discount grouping for customers</item>
///   <item><c>Cust. Invoice Disc.</c> - Invoice-level discounts by minimum amount</item>
///   <item><c>Sales Price Worksheet</c> - Batch price change management</item>
/// </list>
/// <para><b>Entry Points:</b> Use <c>Sales Prices</c> page for price management,
/// <c>Sales Price Lists</c> for extended pricing, <c>Sales Price Calc. Mgt.</c> codeunit for price calculations.</para>
/// </remarks>
namespace Microsoft.Sales.Pricing;
