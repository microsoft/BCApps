// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive reporting capabilities for sales operations, customer analysis, and accounts receivable management.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The Sales Reports namespace contains printed and displayed reports for analyzing customer transactions,
/// aging analysis, trial balances, sales statistics, and salesperson performance. Reports retrieve data
/// primarily from Customer Ledger Entries, Detailed Customer Ledger Entries, and Sales Header/Line tables.
/// Most reports support multiple output formats including RDLC, Word, and Excel layouts.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
///   <item>Customer aging analysis - Generate aging reports to analyze overdue receivables by period</item>
///   <item>Trial balance reporting - Produce customer trial balances with opening/closing amounts</item>
///   <item>Sales statistics - Analyze sales performance, profits, and discounts by customer or salesperson</item>
///   <item>Order tracking - Review outstanding orders and their expected delivery dates</item>
///   <item>Statement generation - Create customer balance statements for collection purposes</item>
///   <item>Document testing - Validate sales documents before posting</item>
/// </list>
/// <para>
/// <b>Core Reports:</b>
/// </para>
/// <list type="bullet">
///   <item><c>Customer - Summary Aging</c> - Aging analysis with configurable period lengths</item>
///   <item><c>Customer - Detail Trial Bal.</c> - Detailed trial balance with ledger entries</item>
///   <item><c>Customer - Balance to Date</c> - Customer statements showing balance details</item>
///   <item><c>Sales Statistics</c> - Profit and sales analysis by period</item>
///   <item><c>Salesperson - Sales Statistics</c> - Sales performance by salesperson</item>
///   <item><c>Salesperson - Commission</c> - Commission calculations for salespeople</item>
///   <item><c>Customer/Item Sales</c> - Item-level sales analysis per customer</item>
///   <item><c>Sales Document - Test</c> - Pre-posting validation for sales documents</item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Reports integrate with Customer master data, Customer Ledger Entries, G/L Registers,
/// Salesperson/Purchaser records, and Inventory for item-level analysis. Many reports
/// support currency handling and show amounts in both local and foreign currencies.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Reports expose integration events for customizing data retrieval and calculations.
/// Custom report layouts can be created using Word or Excel templates. Request page
/// options allow filtering by date ranges, customers, and posting groups.
/// </para>
/// <para>
/// <b>Dependencies:</b><br/>
/// <i>Required:</i> Microsoft.Sales.Customer, Microsoft.Sales.Receivables, Microsoft.Foundation.Company<br/>
/// <i>Optional:</i> Microsoft.CRM.Team, Microsoft.Inventory.Costing, Microsoft.Finance.Currency, Microsoft.Finance.GeneralLedger.Ledger
/// </para>
/// </remarks>
namespace Microsoft.Sales.Reports;
