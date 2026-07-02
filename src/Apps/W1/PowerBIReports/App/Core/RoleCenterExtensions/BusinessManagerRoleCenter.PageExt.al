// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using Microsoft.Finance.RoleCenters;

pageextension 36953 "Business Manager Role Center" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Reporting)
        {
            group("PBI Reports")
            {
                Caption = 'Power BI Reports';
                Image = PowerBI;
                ToolTip = 'Power BI reports across application areas.';
                action("Power BI Reports Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Power BI Reports Setup';
                    Image = Setup;
                    RunObject = page "PowerBI Reports Setup";
                    ToolTip = 'View and edit the setup for the Power BI reports, including report selection and the connection to Power BI.';
                }
                group("Finance Reports")
                {
                    Caption = 'Finance';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for finance.';
                    action("Finance Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Finance Report';
                        Image = "PowerBI";
                        RunObject = page "Finance Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all financial report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Financial Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Financial Overview';
                        Image = "PowerBI";
                        RunObject = page "Financial Overview";
                        Tooltip = 'Open a Power BI Report that provides a snapshot of the organization''s financial health and performance. This page displays key performance indicators that give stakeholders a clear view of revenue, profitability, and financial stability. ';
                    }
                    action("Income Statement by Month")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Income Statement by Month';
                        Image = "PowerBI";
                        RunObject = page "Income Statement by Month";
                        Tooltip = 'Open a Power BI Report that provides a month-to-month comparative view of the net change for income statement accounts.';
                    }
                    action("Balance Sheet by Month")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance Sheet by Month';
                        Image = "PowerBI";
                        RunObject = page "Balance Sheet by Month";
                        Tooltip = 'Open a Power BI Report that provides a month-to-month comparative view of the balance at date for balance sheet accounts. ';
                    }
                    action("Budget Comparison")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Budget Comparison';
                        Image = "PowerBI";
                        RunObject = page "Budget Comparison";
                        Tooltip = 'Open a Power BI Report that presents a month-to-month analysis of Net Change against Budget Amounts for both Balance Sheet and Income Statement accounts. Featuring variance and variance percentage metrics, providing a clear view of how actual performance compares to budgeted targets.';
                    }
                    action("Liquidity KPIs")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Liquidity KPIs';
                        Image = "PowerBI";
                        RunObject = page "Liquidity KPIs";
                        Tooltip = 'Open a Power BI Report that offers insights into three key metrics: Current Ratio, Quick Ratio, and Cash Ratio. Visualizing these metrics over time, the report makes it easy to track trends and assess the company’s liquidity position.';
                    }
                    action("Profitability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Profitability';
                        Image = "PowerBI";
                        RunObject = page "Profitability";
                        Tooltip = 'Open a Power BI Report that highlights Gross Profit and Net Profit, visualizing these metrics over time. It also provides detailed insights into net margins, gross profit margins, and the underlying revenue, cost and expense figures that drive them.';
                    }
                    action("Liabilities")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Liabilities';
                        Image = "PowerBI";
                        RunObject = page "Liabilities";
                        Tooltip = 'Open a Power BI Report that provides a snapshot of liability account balances as of a specific date. It also highlights key performance metrics influenced by liabilities, such as the Debt Ratio and Debt-to-Equity Ratio.';
                    }
                    action("EBITDA")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EBITDA';
                        Image = "PowerBI";
                        RunObject = page "EBITDA";
                        Tooltip = 'Open a Power BI Report that focuses on two key profitability metrics: EBITDA and EBIT. These figures are visualized over time to reveal trends, while Operating Revenue and Operating Expenses are also highlighted to provide supporting context for both measures.';
                    }
                    action("Average Collection Period")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Average Collection Period';
                        Image = "PowerBI";
                        RunObject = page "Average Collection Period";
                        Tooltip = 'Open a Power BI Report that analyses trends in the average collection period over time. It includes supporting details such as the Number of Days, Accounts Receivable, and Accounts Receivable (Average) to provide context and enhance the analysis.';
                    }
                    action("Aged Receivables (Back Dating)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Receivables (Back Dating)';
                        Image = "PowerBI";
                        RunObject = page "Aged Receivables (Back Dating)";
                        Tooltip = 'Open a Power BI Report that categorizes customer balances into aging buckets. It offers flexibility with filters for different payment terms, aging dates, and custom aging bucket sizes.';
                    }
                    action("Aged Payables (Back Dating)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Payables (Back Dating)';
                        Image = "PowerBI";
                        RunObject = page "Aged Payables (Back Dating)";
                        Tooltip = 'Open a Power BI Report that categorizes vendor balances into aging buckets. It offers flexibility with filters for different payment terms, aging dates, and custom aging bucket sizes.';
                    }
                    action("General Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Ledger Entries';
                        Image = "PowerBI";
                        RunObject = page "PowerBI General Ledg. Entries";
                        Tooltip = 'Open a Power BI Report that provides granular detail about the entries posted to the general ledger. ';
                    }
                    action("Detailed Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        Image = "PowerBI";
                        RunObject = page "Detailed Vendor Ledger Entries";
                        Tooltip = 'Open a Power BI Report that provides granular detail about the entries posted to Vendor Ledger and Detailed Vendor Ledger.';
                    }
                    action("Detailed Cust. Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Cust. Ledger Entries';
                        Image = "PowerBI";
                        RunObject = page "Detailed Cust. Ledger Entries";
                        Tooltip = 'Open a Power BI Report that provides granular detail about the entries posted to Customer Ledger and Detailed Customer Sub Ledger.';
                    }
                    action("Inventory Valuation Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation Report';
                        Image = "PowerBI";
                        RunObject = page "Inventory Valuation Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all inventory valuation report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Inventory Valuation Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation Overview';
                        Image = "PowerBI";
                        RunObject = page "Inventory Valuation Overview";
                        Tooltip = 'Open a Power BI Report that  displays the inventory ending balance against the ending balance posted to the general ledger. Inventory value by location is plotted on a bar chart which is supported by inventory metrics such as increase quantity and decrease quantity. ';
                    }
                    action("Inventory Valuation by Item")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation by Item';
                        Image = "PowerBI";
                        RunObject = page "Inventory Valuation by Item";
                        Tooltip = 'Open a Power BI Report that features a Treemap that visualizes ending balance quantities by item category. It also includes a table matrix providing a detailed view of ending balances and showing fluctuations in inventory over the specified period.';
                    }
                    action("Inventory Valuation by Location")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation by Location';
                        Image = "PowerBI";
                        RunObject = page "Inventory Valuation by Loc.";
                        Tooltip = 'Open a Power BI Report that features a Treemap that visualizes ending balance quantities by location. It also includes a table matrix providing a detailed view of ending balances and showing fluctuations in inventory over the specified period.';
                    }
                    action("Late Payments (Receivables)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Late Payments (Receivables)';
                        Image = "PowerBI";
                        RunObject = page "Late Payments (Receivables)";
                        Tooltip = 'Open the Power BI report that visualizes the late payment behaviours of customers, including amounts and payment times, to analyze the financial impacts of late payments on the business.';
                    }
                }
                group("Sales Reports")
                {
                    Caption = 'Sales';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for sales.';
                    action("Sales Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Report';
                        Image = "PowerBI";
                        RunObject = page "Sales Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all sales report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Sales Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Overview';
                        Image = "PowerBI";
                        RunObject = page "Sales Overview";
                        Tooltip = 'Open a Power BI Report that provides a comprehensive view of sales performance, offering insights into metrics such as Total Sales, Gross Profit Margin, Number of New Customers, and top-performing customers and salespeople.';
                    }
                    action("Daily Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Daily Sales';
                        Image = "PowerBI";
                        RunObject = page "Daily Sales";
                        Tooltip = 'Open a Power BI Report that offers a detailed analysis of sales amounts by weekday. The tabular report highlights trends by using conditional formatting to display figures in a gradient from low to high.';
                    }
                    action("Sales Moving Average")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Average';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Average";
                        Tooltip = 'Open a Power BI Report that visualizes the 30-day moving average of sales amounts over time. This helps identify trends by smoothing out fluctuations and highlighting overall patterns.';
                    }
                    action("Sales Moving Annual Total")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Annual Total';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Annual Total";
                        Tooltip = 'Open a Power BI Report that provides a rolling 12-month view of sales figures, tracking the current year to the previous year''s performance. ';
                    }
                    action("Sales Period-Over-Period")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Period-Over-Period';
                        Image = "PowerBI";
                        RunObject = page "Sales Period-Over-Period";
                        Tooltip = 'Open a Power BI Report that compares sales performance across different periods, such as month-over-month or year-over-year.';
                    }
                    action("Sales Month-To-Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Month-To-Date';
                        Image = "PowerBI";
                        RunObject = page "Sales Month-To-Date";
                        Tooltip = 'Open a Power BI Report that tracks the accumulation of sales amounts throughout the current month, providing insights into progress and performance up to the present date.';
                    }
                    action("Sales by Item")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Item';
                        Image = "PowerBI";
                        RunObject = page "Sales by Item";
                        Tooltip = 'Open a Power BI Report that breaks down sales performance by item category, highlighting metrics such as Sales Amount, Gross Profit Margin, and Gross Profit as a Percent of the Grand Total. This report provides detailed insights into which categories and items are driving revenue and profitability.';
                    }
                    action("Sales by Customer")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Customer';
                        Image = "PowerBI";
                        RunObject = page "Sales by Customer";
                        Tooltip = 'Open a Power BI Report that breaks down sales performance highlighting key metrics such as Sales Amount, Cost Amount, Gross Profit and Gross Profit Margin by customer. This report provides detailed insights into which customer and items driving revenue and profitability.';
                    }
                    action("Sales by Salesperson")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Salesperson';
                        Image = "PowerBI";
                        RunObject = page "Sales by Salesperson";
                        Tooltip = 'Open a Power BI Report that breaks down salesperson performance by customer and item. Highlighting metrics such as Sales Amount, Sales Quantity, Gross Profit and Gross Profit Margin.';
                    }
                    action("Sales Actual vs. Budget Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Actual vs. Budget';
                        Image = "PowerBI";
                        RunObject = page "Sales Actual vs. Budget Qty.";
                        Tooltip = 'Open a Power BI Report that provides a comparative analysis of sales quantity to budget amounts/quantities. Featuring variance and variance percentage metrics that provide a clear view of actual performance compared to budgeted targets.';
                    }
                    action("Sales Demographics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Demographics';
                        Image = "PowerBI";
                        RunObject = page "Sales Demographics";
                        Tooltip = 'Open the Power BI report that shows sales data segmented by demographic factors including sales metrics by item category, sales by customer posting group, sales by document type and the number of customers by location.';
                    }
                    action("Sales Decomposition")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Decomposition';
                        Image = "PowerBI";
                        RunObject = page "Sales Decomposition";
                        Tooltip = 'Open the Power BI report that breaks down sales figures to understand contributing factors including location names, item categories, and countries and regions.';
                    }
                    action("Key Sales Influencers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Sales Influencers';
                        Image = "PowerBI";
                        RunObject = page "Key Sales Influencers";
                        Tooltip = 'Open the Power BI report that identifies and analyzes the main factors influencing sales performance, highlighting the most impactful variables and trends based on the sales data like items, customers and dimensions.';
                    }
                    action("Opportunity Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opportunity Overview';
                        Image = "PowerBI";
                        RunObject = page "Opportunity Overview";
                        Tooltip = 'Open the Power BI report that provides a comprehensive view of sales opportunities, including the number of opportunities, estimated values, sales cycle, and a breakdown of potential value by location.';
                    }
                    action("Sales Quote Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Overview';
                        Image = "PowerBI";
                        RunObject = page "Sales Quote Overview";
                        Tooltip = 'Open the Power BI report that provides detailed information on sales quotes, including the number of quotes, total value, profit rates, and sales quote amount over time.';
                    }
                    action("Return Order Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Order Overview';
                        Image = "PowerBI";
                        RunObject = page "Return Order Overview";
                        Tooltip = 'Open the Power BI report that tracks and analyzes return orders, providing insights into return amounts, quantities,  reasons for return, and the financial impact on the organization.';
                    }
                    action("Sales Forecasting")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Forecasting';
                        Image = "PowerBI";
                        RunObject = page "Sales Forecasting";
                        Tooltip = 'Open the Power BI Report that predicts your sales trends, including forecasting of sales metrics across item, customer, document type and salespeople.';
                    }
                    action("Sales by Projects")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Projects';
                        Image = "PowerBI";
                        RunObject = page "Sales by Projects";
                        Tooltip = 'Open the Power BI Report that breaks down sales performance by project, including sales metrics across customer, item, resources and general ledger accounts.';
                    }
                    action("Customer Retention Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention Overview';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention Overview";
                        Tooltip = 'Open the Power BI Report that analyzes customer retention, providing insights into repeat purchase behavior, customer loyalty, and trends in customer churn over time.';
                    }
                    action("Customer Retention History")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention History';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention History";
                        Tooltip = 'Open the Power BI Report that provides historical insights into customer retention metrics, allowing analysis of retention trends over time.';
                    }
                }
                group("Purchasing Reports")
                {
                    Caption = 'Purchasing';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for purchasing.';
                    action("Purchases Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Report';
                        Image = "PowerBI";
                        RunObject = page "Purchases Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all purchases report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Purchases Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Overview';
                        Image = "PowerBI";
                        RunObject = page "Purchases Overview";
                        Tooltip = 'Open a Power BI Report that provides high level insights into procurement performance, highlighting metrics such as Outstanding Quantities, Quantity Received not Invoiced and Invoice Quantity. ';
                    }
                    action("Purchases Decomposition")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Decomposition';
                        Image = "PowerBI";
                        RunObject = page "Purchases Decomposition";
                        Tooltip = 'Open a Power BI Report that visually breaks down Purchase Amount into its contributing factors, allowing users to explore and analyze data hierarchies in detail.';
                    }
                    action("Daily Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Daily Purchases';
                        Image = "PowerBI";
                        RunObject = page "Daily Purchases";
                        Tooltip = 'Open a Power BI Report that offers a detailed analysis of purchase amounts by weekday. The tabular report highlights purchasing trends by using conditional formatting to display purchase figures in a gradient from low to high.';
                    }
                    action("Purchases Moving Averages")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Moving Averages';
                        Image = "PowerBI";
                        RunObject = page "Purchases Moving Averages";
                        Tooltip = 'Open a Power BI Report that visualizes the 30-day moving average of purchase amounts over time. This helps identify trends by smoothing out fluctuations and highlighting overall patterns.';
                    }
                    action("Purchases Moving Annual Total")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Moving Annual Total';
                        Image = "PowerBI";
                        RunObject = page "Purchases Moving Annual Total";
                        Tooltip = 'Open a Power BI Report that provides a rolling 12-month view of procurement figures, tracking current year to the previous year''s performance. ';
                    }
                    action("Purchases Period-Over-Period")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Period-Over-Period';
                        Image = "PowerBI";
                        RunObject = page "Purchases Period-Over-Period";
                        Tooltip = 'Open a Power BI Report that compares procurement performance across different periods, such as month-over-month or year-over-year. Completed up to here';
                    }
                    action("Purchases Year-Over-Year")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases Year-Over-Year';
                        Image = "PowerBI";
                        RunObject = page "Purchases Year-Over-Year";
                        Tooltip = 'Open a Power BI Report that compares purchase amounts across multiple years. This report is essential for long-term planning and making informed decisions based on historical purchasing data.';
                    }
                    action("Purchases by Item")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases by Item';
                        Image = "PowerBI";
                        RunObject = page "Purchases by Item";
                        Tooltip = 'Open a Power BI Report that breaks down procurement performance by item, highlighting metrics such as Purchase Amount, Purchase Quantity. The Treemap visualizes the relative size and contribution of each item to the whole, making it easy to identify the largest or smallest purchases at a glance.';
                    }
                    action("Purchases by Purchaser")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases by Purchaser';
                        Image = "PowerBI";
                        RunObject = page "Purchases by Purchaser";
                        Tooltip = 'Open a Power BI Report that breaks down purchase amounts by individual purchasers, using a Treemap to visually compare spending contributions by item. A bar chart complements this, displaying purchase amounts for each purchaser. Making it easy to identify top spenders and track procurement patterns.';
                    }
                    action("Purchases by Vendor")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases by Vendor';
                        Image = "PowerBI";
                        RunObject = page "Purchases by Vendor";
                        Tooltip = 'Open a Power BI Report that shows purchase amounts and quantities by vendor. Featuring a Treemap for item spending contributions and a bar chart for purchase amounts by item category, offering a clear view of vendor performance and spending patterns.';
                    }
                    action("Purchases by Location")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases by Location';
                        Image = "PowerBI";
                        RunObject = page "Purchases by Location";
                        Tooltip = 'Open a Power BI Report that displays purchase amounts and quantities by location. Including a Treemap to highlight item spending contributions and a bar chart to show purchase amounts by item category.';
                    }
                    action("Purch. Actual vs. Budget Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purch. Actual vs. Budget Qty.';
                        Image = "PowerBI";
                        RunObject = page "Purch. Actual vs. Budget Qty.";
                        Tooltip = 'Open a Power BI Report that offers a comparative analysis of purchase quantities against budgeted quantities. It includes variance and variance percentage metrics to clearly show how actual purchases align with budgeted targets.';
                    }
                    action("Purch. Actual vs. Budget Amt.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purch. Actual vs. Budget Amt.';
                        Image = "PowerBI";
                        RunObject = page "Purch. Actual vs. Budget Amt.";
                        Tooltip = 'Open a Power BI Report that offers a comparative analysis of purchase amounts against budgeted amounts. It includes variance and variance percentage metrics to clearly show how actual purchases align with budgeted targets.';
                    }
                    action("Purchase Forecasting")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Forecasting';
                        Image = "PowerBI";
                        RunObject = page "Purchase Forecasting";
                        Tooltip = 'Open the Power BI Report that predicts your purchasing trends, including forecasting of purchase metrics across item, vendor, and purchaser.';
                    }
                    action("Vendor Quality Analysis")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Quality Analysis';
                        Image = "PowerBI";
                        RunObject = page "Vendor Quality Analysis";
                        Tooltip = 'Open the Power BI report that analyses the quality of Vendors, featuring insights on returns, discounts and single-supplier items. This report highlights effective vendor relationships to continuously improve supplier performance.';
                    }
                    action("Key Purchase Influencers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Purchase Influencers';
                        Image = "PowerBI";
                        RunObject = page "Key Purchase Influencers";
                        Tooltip = 'Open the Power BI report that identifies and analyzes the main factors influencing purchase performance, highlighting the most impactful variables and trends based on the purchase data like items, vendor and dimensions.';
                    }
                    action("Purchase Quote Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Quote Overview';
                        Image = "PowerBI";
                        RunObject = page "Purchase Quote Overview";
                        Tooltip = 'Open the Power BI report that provides detailed information on purchase quotes, including the number of quotes, total value and purchase quote amount over time.';
                    }
                }
                group("Inventory Reports")
                {
                    Caption = 'Inventory';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for inventory.';
                    action("Inventory Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Report';
                        Image = "PowerBI";
                        RunObject = page "Inventory Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all inventory report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Inventory Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Overview';
                        Image = "PowerBI";
                        RunObject = page "Inventory Overview";
                        Tooltip = 'Open a Power BI Report that offers a dashboard view of inventory, featuring key elements such as inventory by location, a comparison of inventory balance versus projected available balance, and key metrics like scheduled receipt quantities and gross requirements.';
                    }
                    action("Inventory by Item")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory by Item';
                        Image = "PowerBI";
                        RunObject = page "Inventory by Item";
                        Tooltip = 'Open a Power BI Report that provides inventory quantities by item, offering insights into the sources of supply and demand. Helping organizations understand item-level inventory status, manage stock effectively, and make informed decisions about the state of supply and demand.';
                    }
                    action("Inventory by Location")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory by Location';
                        Image = "PowerBI";
                        RunObject = page "Inventory by Location";
                        Tooltip = 'Open a Power BI Report that shows inventory quantities by item and by location. ';
                    }
                    action("Purchase and Sales Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase and Sales Quantity';
                        Image = "PowerBI";
                        RunObject = page "Purchase and Sales Quantity";
                        Tooltip = 'Open a Power BI Report that offers insight into inventory movements by visualizing Net Quantity Purchased and Net Quantity Sold across time. The table matrix breaks down purchases and sales by item and item category code, targeting insights into supply from purchases and demand from sales. ';
                    }
                    action("Item Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Availability';
                        Image = "PowerBI";
                        RunObject = page "Item Availability";
                        Tooltip = 'Open a Power BI Report that visualizes Quantity on Hand versus Projected Available Balance over time, helping track inventory trends. A table matrix breaks down this data by item, offering metrics such as Inventory, Projected Available Balance, Gross Requirements, Scheduled Receipts, Planned Order Receipts, and Planned Order Releases. Providing a comprehensive view of item availability, aiding in effective inventory management and planning.';
                    }
                    action("Gross Requirement")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gross Requirement';
                        Image = "PowerBI";
                        RunObject = page "Gross Requirement";
                        Tooltip = 'Open a Power BI Report that visualizes Gross Requirements against Projected Available Balance over time, offering a clear view of inventory demands. A table matrix breaks down this data by item, showcasing key metrics like Gross Requirement, Projected Available Balance, and quantities from demand documents (sales orders and purchase return orders). ';
                    }
                    action("Scheduled Receipt")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Scheduled Receipt';
                        Image = "PowerBI";
                        RunObject = page "Scheduled Receipt";
                        Tooltip = 'Open a Power BI Report that visualizes Scheduled Receipt against Projected Available Balance over time, offering a clear view of inventory supply. A table matrix breaks this down by item, showcasing key metrics like Scheduled Receipt Quantity, Projected Available Balance, and quantities from supply documents such as purchase orders, transfer receipts and manufacturing documents.';
                    }
                    action("Inventory by Lot")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory by Lot';
                        Image = "PowerBI";
                        RunObject = page "Inventory by Lot";
                        Tooltip = 'Open a Power BI Report that displays inventory quantities categorized by lot number, providing detailed insights into specific batches of stock. A decomposition tree enhances this by allowing users to drill down into inventory data, breaking down lot quantities by various dimensions such as location, item category, or vendor.';
                    }
                    action("Inventory by Serial No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory by Serial No.';
                        Image = "PowerBI";
                        RunObject = page "Inventory by Serial No.";
                        Tooltip = 'Open a Power BI Report that displays inventory quantities categorized by serial number. The decomposition tree enhances this report by allowing users to drill down into inventory data, breaking down quantities by various dimensions such as location, item category, or vendor.';
                    }
                    action("Bin Contents")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bin Contents';
                        Image = "PowerBI";
                        RunObject = page "PowerBI Bin Contents";
                        Tooltip = 'Open a Power BI Report that provides a detailed view of item quantities by bin code and location. It includes additional information such as warehouse quantity, pick and put-away quantities, and both negative and positive adjustments, offering a comprehensive overview of bin movements and inventory management within the warehouse.';
                    }
                    action("Bin Contents by Item Tracking")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bin Contents by Item Tracking';
                        Image = "PowerBI";
                        RunObject = page "Bin Contents by Item Tracking";
                        Tooltip = 'Open a Power BI Report that provides a detailed view of warehouse quantities by Item, Location, Bin Code, Zone Code, Lot number or Serial number. ';
                    }
                    action("Inventory Forecasting")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Forecasting';
                        Image = "PowerBI";
                        RunObject = page "Inventory Forecasting";
                        Tooltip = 'Open the Power BI Report that predicts your inventory trends, including forecasting of quantity across item, location and inventory posting groups.';
                    }
                    action("ABC Analysis")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ABC Analysis';
                        Image = "PowerBI";
                        RunObject = page "PowerBI ABC Analysis";
                        Tooltip = 'Open the Power BI Report that performs an ABC analysis of your sales data, categorizing customers based on their contribution to total sales.';
                    }
                }
                group("Manufacturing Reports")
                {
                    Caption = 'Manufacturing';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for manufacturing.';
                    action("Work Center Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Work Center Statistics';
                        Image = "PowerBI";
                        RunObject = page "PBI Work Center Statistics";
                        Tooltip = 'Open the Power BI report that shows your work center statistics and detailed metrics on total and effective capacity, expected and actual efficiency, actual need, cost, and allocated time.';
                    }
                    action("Machine Center Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Machine Center Statistics';
                        Image = "PowerBI";
                        RunObject = page "PBI Machine Center Statistics";
                        Tooltip = 'Open the Power BI report that shows your machine center statistics and discover detailed metrics on total and effective capacity, expected and actual efficiency, scrap rates, and output.';
                    }
                    action("Machine Center Load")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Machine Center Load';
                        Image = "PowerBI";
                        RunObject = page "PBI Machine Center Load";
                        Tooltip = 'Open the Power BI report that shows your machine center load and usage, including allocated time and availability for each machine center, helping you optimize resource allocation and improve operational efficiency.';
                    }
                    action("Prod. Order - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Production Order - List';
                        Image = "PowerBI";
                        RunObject = page "Prod. Order - List";
                        Tooltip = 'Open the Power BI report that lists all production orders and analyzes detailed production order information, including status, due date, and planned versus finished quantities.';
                    }
                    action("Production Order Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Production Order Overview';
                        Image = "PowerBI";
                        RunObject = page "Production Order Overview";
                        Tooltip = 'Open the Power BI report that presents key metrics and charts including a breakdown of total actual costs, the number of production orders by status, and the completion percentages for each source item.';
                    }
                    action("Prod. Order Routings Gantt")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Production Order Routings Gantt';
                        Image = "PowerBI";
                        RunObject = page "Prod. Order Routings Gantt";
                        Tooltip = 'Open the Power BI report that visualizes the schedules of each work and machine center with a Gantt chart, detailing production order routing lines.';
                    }
                    action("Production Order WIP")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Production Order WIP';
                        Image = "PowerBI";
                        RunObject = page "Production Order WIP";
                        Tooltip = 'Open the Power BI report that shows inventory valuation for selected production orders in your WIP inventory.';
                    }
                    action("Expected Capacity Need")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Expected Capacity Need';
                        Image = "PowerBI";
                        RunObject = page "Expected Capacity Need";
                        Tooltip = 'Open a Power BI Report to view the total hours scheduled to be performed for each Work Centre Group and/or Work Centre broken down by production order status and production order to analyze your requirement on factory resources.';
                    }
                    action("Manufacturing Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manufacturing Report';
                        Image = "PowerBI";
                        RunObject = page "Manufacturing Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all manufacturing report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Finished Prod. Order Breakdown")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Finished Production Order Breakdown';
                        Image = "PowerBI";
                        RunObject = page "Finished Prod. Order Breakdown";
                        Tooltip = 'Open a Power BI Report to view Expected Quantities and Cost vs. Actual Quantities and Costs over time, analyze the detail per item and drill down to the Production Order to track where variances are occurring.';
                    }
                    action("Average Productions Times")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Average Productions Times';
                        Image = "PowerBI";
                        RunObject = page "Average Productions Times";
                        Tooltip = 'Open a Power BI Report to view the average time spent for Setup, Run and Stop times per unit for each manufactured Item. Expand to see the times for each production order to determine why fluctuations occurred.';
                    }
                    action("Released Production Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Released Production Orders';
                        Image = "PowerBI";
                        RunObject = page "PowerBI Released Prod. Orders";
                        Tooltip = 'Open a Power BI Report to view how your released production orders are tracking by comparing Expected Quantity vs. Finished Quantity';
                    }
                    action("Work Center Load")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Work Center Load';
                        Image = "PowerBI";
                        RunObject = page "PowerBI Work Center Load";
                        Tooltip = 'Open a Power BI Report to view the percentage of production order time assigned vs. Available Capacity for each Work Centre Group and/or Work Centre in a specified period. Allows you to determine if a Work Centre is overloaded and requires rescheduling.';
                    }
                    action("Allocated Hours")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Allocated Hours';
                        Image = "PowerBI";
                        RunObject = page "Allocated Hours";
                        Tooltip = 'Open a Power BI Report to view the number of hours remaining for production allocated to each Work Centre in a specified period. Allows you to determine if a Work Centre is under or overloaded and requires rescheduling.';
                    }
                    action("Consumption Variance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Consumption Variance';
                        Image = "PowerBI";
                        RunObject = page "Consumption Variance";
                        Tooltip = 'Open a Power BI Report to view your consumption cost variance % viewed over a timeline you can define to see trends. Analyze by each production order and filter by Work Centre to see the detail behind the overall percentages.';
                    }
                    action("Capacity Variance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Capacity Variance';
                        Image = "PowerBI";
                        RunObject = page "Capacity Variance";
                        Tooltip = 'Open a Power BI Report to view your capacity cost variance % viewed over a timeline you can define to see trends. Analyze by each production order and filter by Work Centre to see the detail behind the overall percentages.';
                    }
                    action("Production Scrap")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Production Scrap';
                        Image = "PowerBI";
                        RunObject = page "Production Scrap";
                        Tooltip = 'Open a Power BI Report to view your scrap quantities over a timeline you can define to see trends. Analyze further by Scrap Code, Location, Item Categories and by filtering for specific items.';
                    }
                }
                group("Projects Reports")
                {
                    Caption = 'Projects';
                    Image = PowerBI;
                    ToolTip = 'Power BI reports for projects.';
                    action("Projects Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Projects Report';
                        Image = "PowerBI";
                        RunObject = page "Projects Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all project report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Projects Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Projects Overview';
                        Image = "PowerBI";
                        RunObject = page "Projects Overview";
                        Tooltip = 'Open a Power BI Report that provides key insights into project performance with metrics like Percent Complete, Percent Invoiced, Realization Percent, Actual Profit, and Actual Profit Margin. It features visuals comparing Actual vs. Budgeted Costs, highlighting Profit per Project, and organizing projects by Project Manager for streamlined project management.';
                    }
                    action("Project Tasks")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Tasks';
                        Image = "PowerBI";
                        RunObject = page "Project Tasks";
                        Tooltip = 'Open a Power BI Report that details tasks related to each project, with metrics for each task clearly outlined. It presents tasks in a table matrix in a hierarchical view, making it easy to navigate and analyze project task information.';
                    }
                    action("Project Profitability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Profitability';
                        Image = "PowerBI";
                        RunObject = page "Project Profitability";
                        Tooltip = 'Open a Power BI Report that displays key metrics such as Actuals and Budgeted KPIs, compares actual profit to the initial profit target, and includes a table view of project ledger entries by type.';
                    }
                    action("Project Realization")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Realization';
                        Image = "PowerBI";
                        RunObject = page "Project Realization";
                        Tooltip = 'Open a Power BI Report that features key metrics like Billable Invoice Price and Actual Total Price to support Realization percent per project. Enabling organizations to measure actual performance and achievements against planned or budgeted expectations.';
                    }
                    action("Project Performance to Budget")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Performance to Budget';
                        Image = "PowerBI";
                        RunObject = page "Project Performance to Budget";
                        Tooltip = 'Open a Power BI Report that highlights key metrics, including Budget Total Cost, Actual Total Cost, and the variance and percentage variance from the budget. It features a table that details these metrics by project, offering a clear view of cost performance and deviations from budgeted targets.';
                    }
                    action("Project Invoiced Sales by Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Invoiced Sales by Type';
                        Image = "PowerBI";
                        RunObject = page "Project Invoiced Sales by Type";
                        Tooltip = 'Open a Power BI Report that details invoiced sales for a project categorized by line type. It includes key KPIs such as % Invoiced, Billable Invoiced Price, and Billable Total Price, providing a clear overview of project invoicing performance and statistics.';
                    }
                    action("Project Invd. Sales by Cust.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Project Invd. Sales by Cust.';
                        Image = "PowerBI";
                        RunObject = page "Project Invd. Sales by Cust.";
                        Tooltip = 'Open a Power BI Report that details invoiced sales for a project, broken down by customer. It includes key KPIs such as % Invoiced, Billable Invoiced Price, and Billable Total Price, offering a clear view of project invoicing by customer. ';
                    }
                }
            }
        }
    }
}
