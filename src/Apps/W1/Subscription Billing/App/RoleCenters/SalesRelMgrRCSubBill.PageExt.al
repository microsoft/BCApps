#pragma warning disable AS0072
namespace Microsoft.SubscriptionBilling;

using Microsoft.CRM.RoleCenters;
using Microsoft.PowerBIReports;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

pageextension 8019 "Sales Rel. Mgr. RC Sub. Bill." extends "Sales & Relationship Mgr. RC"
{
    actions
    {
        addlast(sections)
        {
            group("Sub. Billing")
            {
                Caption = 'Subscription Billing';
                Image = AnalysisView;
                ToolTip = 'Manage recurring subscriptions, subscription contracts, and subscription billing.';
                action(ServiceObjects)
                {
                    ApplicationArea = All;
                    Caption = 'Subscriptions';
                    Image = ServiceSetup;
                    RunObject = page "Service Objects";
                    ToolTip = 'Detailed information on the Subscriptions. The Subscriptions shows the item for which it was created and the Subscription Lines that belong to it. The amount and the details of the provision can be seen. The service recipient indicates to which customer the Subscription Item was sold. Different delivery and billing addresses provide information about who the item was delivered to and who received the invoice. In addition, the Subscription Lines are shown in detail and can be edited.';
                }
                action(CustomerContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Sub. Contracts';
                    Image = Customer;
                    RunObject = page "Customer Contracts";
                    ToolTip = 'Detailed information on Customer Subscription Contracts that include recurring subscriptions. A Customer Subscription Contract is used to calculate these Subscription Lines based on the parameters specified in the Subscription Lines. The Subscription Lines are presented in detail and can be edited. In addition, commercial information as well as delivery and billing addresses can be stored in a Contract.';
                }
                action(VendorContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Sub. Contracts';
                    Image = Vendor;
                    RunObject = page "Vendor Contracts";
                    ToolTip = 'Detailed information on Vendor Subscription Contracts that include recurring subscriptions. A Vendor Subscription Contract is used to calculate these Subscription Lines based on the parameters specified in the Subscription Lines. The Subscription Lines are presented in detail and can be edited. In addition, commercial information can be stored in a Contract.';
                }
                action(OverdueServiceCommitments)
                {
                    ApplicationArea = All;
                    Caption = 'Overdue Subscription Lines';
                    Image = ServiceLedger;
                    RunObject = page "Overdue Service Commitments";
                    ToolTip = 'View overdue subscription lines that need attention.';
                }
                action("Subscription Billing Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Billing (Power BI)';
                    Image = "PowerBI";
                    RunObject = page "Sub. Billing Report Power BI";
                    ToolTip = 'The Subscription Billing Report offers a consolidated view of all subscription report pages, conveniently embedded into a single page for easy access.';
                }
            }
        }
        addlast(sections)
        {
            group("PBI Reports")
            {
                Caption = 'Power BI Reports';
                Image = AnalysisView;
                ToolTip = 'Power BI reports for sales and subscription billing.';
                group("PBI Sales Reports")
                {
                    Caption = 'Sales';
                    action("Sales Report (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Report (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Report";
                        Tooltip = 'Open a Power BI Report that offers a consolidated view of all sales report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Sales Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Overview";
                        Tooltip = 'Open a Power BI Report that provides a comprehensive view of sales performance, offering insights into metrics such as Total Sales, Gross Profit Margin, Number of New Customers, and top-performing customers and salespeople.';
                    }
                    action("Daily Sales (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Daily Sales (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Daily Sales";
                        Tooltip = 'Open a Power BI Report that offers a detailed analysis of sales amounts by weekday. The tabular report highlights trends by using conditional formatting to display figures in a gradient from low to high.';
                    }
                    action("Sales Moving Average (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Average (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Average";
                        Tooltip = 'Open a Power BI Report that visualizes the 30-day moving average of sales amounts over time. This helps identify trends by smoothing out fluctuations and highlighting overall patterns.';
                    }
                    action("Sales Moving Annual Total (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Annual Total (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Annual Total";
                        Tooltip = 'Open a Power BI Report that provides a rolling 12-month view of sales figures, tracking the current year to the previous year''s performance. ';
                    }
                    action("Sales Period-Over-Period (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Period-Over-Period (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Period-Over-Period";
                        Tooltip = 'Open a Power BI Report that compares sales performance across different periods, such as month-over-month or year-over-year.';
                    }
                    action("Sales Month-To-Date (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Month-To-Date (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Month-To-Date";
                        Tooltip = 'Open a Power BI Report that tracks the accumulation of sales amounts throughout the current month, providing insights into progress and performance up to the present date.';
                    }
                    action("Sales by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Item";
                        Tooltip = 'Open a Power BI Report that breaks down sales performance by item category, highlighting metrics such as Sales Amount, Gross Profit Margin, and Gross Profit as a Percent of the Grand Total. This report provides detailed insights into which categories and items are driving revenue and profitability.';
                    }
                    action("Sales by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Customer";
                        Tooltip = 'Open a Power BI Report that breaks down sales performance highlighting key metrics such as Sales Amount, Cost Amount, Gross Profit and Gross Profit Margin by customer. This report provides detailed insights into which customer and items driving revenue and profitability.';
                    }
                    action("Sales by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Salesperson";
                        Tooltip = 'Open a Power BI Report that breaks down salesperson performance by customer and item. Highlighting metrics such as Sales Amount, Sales Quantity, Gross Profit and Gross Profit Margin.';
                    }
                    action("Sales Actual vs. Budget Qty. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Actual vs. Budget (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Actual vs. Budget Qty.";
                        Tooltip = 'Open a Power BI Report that provides a comparative analysis of sales quantity to budget amounts/quantities. Featuring variance and variance percentage metrics that provide a clear view of actual performance compared to budgeted targets.';
                    }
                    action("Sales Demographics (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Demographics (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Demographics";
                        Tooltip = 'Open the Power BI report that shows sales data segmented by demographic factors including sales metrics by item category, sales by customer posting group, sales by document type and the number of customers by location.';
                    }
                    action("Sales Decomposition (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Decomposition (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Decomposition";
                        Tooltip = 'Open the Power BI report that breaks down sales figures to understand contributing factors including location names, item categories, and countries and regions.';
                    }
                    action("Key Sales Influencers (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Sales Influencers (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Key Sales Influencers";
                        Tooltip = 'Open the Power BI report that identifies and analyzes the main factors influencing sales performance, highlighting the most impactful variables and trends based on the sales data like items, customers and dimensions.';
                    }
                    action("Opportunity Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opportunity Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Opportunity Overview";
                        Tooltip = 'Open the Power BI report that provides a comprehensive view of sales opportunities, including the number of opportunities, estimated values, sales cycle, and a breakdown of potential value by location.';
                    }
                    action("Sales Quote Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Quote Overview";
                        Tooltip = 'Open the Power BI report that provides detailed information on sales quotes, including the number of quotes, total value, profit rates, and sales quote amount over time.';
                    }
                    action("Return Order Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Order Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Return Order Overview";
                        Tooltip = 'Open the Power BI report that tracks and analyzes return orders, providing insights into return amounts, quantities,  reasons for return, and the financial impact on the organization.';
                    }
                    action("Sales Forecasting (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Forecasting (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Forecasting";
                        Tooltip = 'Open the Power BI Report that predicts your sales trends, including forecasting of sales metrics across item, customer, document type and salespeople.';
                    }
                    action("Sales by Projects (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Projects (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Projects";
                        Tooltip = 'Open the Power BI Report that breaks down sales performance by project, including sales metrics across customer, item, resources and general ledger accounts.';
                    }
                    action("Customer Retention Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention Overview";
                        Tooltip = 'Open the Power BI Report that analyzes customer retention, providing insights into repeat purchase behavior, customer loyalty, and trends in customer churn over time.';
                    }
                    action("Customer Retention History (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention History (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention History";
                        Tooltip = 'Open the Power BI Report that provides historical insights into customer retention metrics, allowing analysis of retention trends over time.';
                    }
                }
                group("PBI Sub. Billing Reports")
                {
                    Caption = 'Subscription Billing';
                    action("Subscription Billing Report (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Billing Report (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sub. Billing Report Power BI";
                        ToolTip = 'The Subscription Billing Report offers a consolidated view of all subscription report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Subscription Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Subscription Overview Power BI";
                        ToolTip = 'The Subscription Overview provides a comprehensive view of subscription performance, offering insights into metrics such as Monthly Recurring Revenue, Total Contract Value, Churn and top-performing customers or vendors.';
                    }
                    action("Revenue YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue YoY Power BI";
                        ToolTip = 'The Revenue YoY report compares Monthly Recurring Revenue performance across a year-over-year period.';
                    }
                    action("Revenue Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Analysis Power BI";
                        ToolTip = 'The Revenue Analysis report breaks down Monthly Recurring Revenue by various dimension such as billing rhythm, contract type or customer.';
                    }
                    action("Revenue Development (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Development (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Development Power BI";
                        ToolTip = 'The Revenue Development report shows the change in monthly recurring revenue and helps to identify its various sources such as churn, downgrades, new subscriptions or upgrades.';
                    }
                    action("Churn Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Churn Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Churn Analysis Power BI";
                        ToolTip = 'The Churn Analysis report breaks down churn by various dimensions such as contract term, contract type or product.';
                    }
                    action("Revenue by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Item Power BI";
                        ToolTip = 'The Revenue by Item report breaks down subscription performance by item category, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which categories and items are driving subscription revenue and profitability.';
                    }
                    action("Revenue by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Customer Power BI";
                        ToolTip = 'The Revenue by Customer report breaks down subscription performance by customer and item, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which customers and items are driving subscription revenue and profitability.';
                    }
                    action("Revenue by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Rev. by Salesperson Power BI";
                        ToolTip = 'The Revenue by Salesperson report breaks down subscription performance by Salesperson, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Churn.';
                    }
                    action("Total Contract Value YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Value YoY Power BI";
                        ToolTip = 'The Total Contract Value YoY report compares the Total Contract Value and Active Customers across a year-over-year period.';
                    }
                    action("Total Contract Value Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Val Analysis Power BI";
                        ToolTip = 'The Total Contract Value Analysis report breaks down Total Contract Value by various dimension such as billing rhythm, contract type or customer.';
                    }
                    action("Customer Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Deferrals Power BI";
                        ToolTip = 'The Customer Deferrals report provides an overview of deferred vs. released subscription sales amount.';
                    }
                    action("Vendor Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Vendor Deferrals Power BI";
                        ToolTip = 'The Vendor Deferrals report provides an overview of deferred vs. released subscription cost amount.';
                    }
                    action("Sales and Cost forecast (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales and Cost forecast (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Cost forecast Power BI";
                        ToolTip = 'The Sales and Cost forecast report provides the forecast of Monthly Recurring Revenue and Monthly Recurring Cost for the future months and years. This report provides detailed insights into which salespersons and customers are driving future subscription performance.';
                    }
                    action("Billing Schedule (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Billing Schedule (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Billing Schedule Power BI";
                        ToolTip = 'The Billing Schedule report provides a forecast of vendor and customer invoiced amounts according to the contractual billing rhythm. It helps to identify future development of incoming and outgoing cash from billed subscriptions.';
                    }
                }
            }
            group(UsageData)
            {
                Caption = 'Usage Data';
                action("Usage Data Suppliers")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Suppliers';
                    RunObject = page "Usage Data Suppliers";
                    ToolTip = 'Opens the list of Usage Data Suppliers.';
                }
                action("Usage Data Imports")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Imports';
                    RunObject = page "Usage Data Imports";
                    ToolTip = 'Opens the list of Usage Data Imports.';
                }
                action("Usage Data Subscriptions")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supp. Subscriptions';
                    RunObject = page "Usage Data Subscriptions";
                    ToolTip = 'Opens the list of Usage Data Subscriptions.';
                }
                action("Usage Data Supplier References")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supplier References';
                    RunObject = page "Usage Data Supp. References";
                    ToolTip = 'Opens the list of Usage Data Supplier References.';
                }
            }
            group("Subscription Billing Setup")
            {
                Caption = 'Subscription Billing Setup';
                Image = Setup;
                ToolTip = 'View the setup.';
                action("Service Contract Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Contract Setup';
                    Image = ServiceAgreement;
                    RunObject = page "Service Contract Setup";
                    ToolTip = 'View or edit Subscription Contract Setup.';
                }
                action("Contract Types")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Contract Types';
                    Image = FileContract;
                    RunObject = page "Contract Types";
                    ToolTip = 'View or edit Subscription Contract Types.';
                }
                action("Service Commitment Templates")
                {
                    ApplicationArea = All;
                    Caption = 'Sub. Package Line Templates';
                    Image = Template;
                    RunObject = page "Service Commitment Templates";
                    ToolTip = 'View or edit Subscription Package Line Templates.';
                }
                action("Service Commitment Packages")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Packages';
                    Image = Template;
                    RunObject = page "Service Commitment Packages";
                    ToolTip = 'View or edit Subscription Packages.';
                }
            }
        }
        addlast(processing)
        {
            action("Recurring Billing")
            {
                ApplicationArea = All;
                Caption = 'Recurring Billing';
                RunObject = page "Recurring Billing";
                ToolTip = 'Opens the page for creating billing proposals for Recurring subscriptions.';
            }
            action("Contract Deferrals Release")
            {
                ApplicationArea = All;
                Caption = 'Contract Deferrals Release';
                RunObject = report "Contract Deferrals Release";
                ToolTip = 'Releases the deferrals for the all contracts.';
            }
            group(Reports)
            {
                Caption = 'Subscription Billing Reports';
                action("Overview Of Contract Components")
                {
                    ApplicationArea = All;
                    Caption = 'Overview of Subscription Contract components';
                    Image = "Report";
                    RunObject = Report "Overview Of Contract Comp";
                    ToolTip = 'Analyze components of your contracts.';
                }
                action("Customer Contract Deferrals Analysis")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Subscription Contract Deferrals Analysis';
                    Image = "Report";
                    RunObject = Report "Cust. Contr. Def. Analysis";
                    ToolTip = 'Analyze Customer Subscription Contract deferrals.';
                }
                action("Vendor Contract Deferrals Analysis")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Subscription Contract Deferrals Analysis';
                    Image = "Report";
                    RunObject = Report "Vend Contr. Def. Analysis";
                    ToolTip = 'Analyze Vendor Subscription Contract deferrals.';
                }
            }
            group("Sub. Billing History")
            {
                Caption = 'Sub. Billing History';
                action("Posted Customer Contract Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Customer Subscription Contract Invoices';
                    Image = PostedOrder;
                    RunObject = page "Posted Sales Invoices";
                    RunPageView = where("Recurring Billing" = const(true));
                    ToolTip = 'Open the list of Posted Sales Invoices for Customer Subscription Contracts.';
                }
                action("Posted Customer Contract Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Customer Subscription Contract Credit Memos';
                    Image = PostedOrder;
                    RunObject = page "Posted Sales Credit Memos";
                    RunPageView = where("Recurring Billing" = const(true));
                    ToolTip = 'Open the list of Posted Sales Credit Memos for Customer Subscription Contracts.';
                }
                action("Posted Vendor Contract Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Vendor Subscription Contract Invoices';
                    Image = PostedOrder;
                    RunObject = page "Posted Purchase Invoices";
                    RunPageView = where("Recurring Billing" = const(true));
                    ToolTip = 'Open the list of Posted Purchase Invoices for Vendor Subscription Contracts.';
                }
                action("Posted Vendor Contract Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Vendor Subscription Contract Credit Memos';
                    Image = PostedOrder;
                    RunObject = page "Posted Purchase Credit Memos";
                    RunPageView = where("Recurring Billing" = const(true));
                    ToolTip = 'Open the list of Posted Purchase Credit Memos for Vendor Subscription Contracts.';
                }
            }
        }
        addlast(New)
        {
            action(ServiceCommitmentTemplate)
            {
                ApplicationArea = All;
                Caption = 'Subscription Package Line Template';
                Image = ApplyTemplate;
                RunObject = page "Service Commitment Templates";
                RunPageMode = Create;
                ToolTip = 'Create a new Subscription Package Line Template.';
            }
            action(ServiceCommitmentPackage)
            {
                ApplicationArea = All;
                Caption = 'Subscription Package';
                Image = ServiceLedger;
                RunObject = page "Service Commitment Package";
                RunPageMode = Create;
                ToolTip = 'Create a new Subscription Package.';
            }
            action(ServiceObject)
            {
                ApplicationArea = All;
                Caption = 'Subscription';
                Image = NewOrder;
                RunObject = Page "Service Object";
                RunPageMode = Create;
                ToolTip = 'Create a new Subscription.';
            }
            action(CustomerContract)
            {
                ApplicationArea = All;
                Caption = 'Customer Subscription Contract';
                Image = NewOrder;
                RunObject = page "Customer Contract";
                RunPageMode = Create;
                ToolTip = 'Create a new Customer Subscription Contract.';
            }
            action(VendorContract)
            {
                ApplicationArea = All;
                Caption = 'Vendor Subscription Contract';
                Image = NewOrder;
                RunObject = page "Vendor Contract";
                RunPageMode = Create;
                ToolTip = 'Create a new Vendor Subscription Contract.';
            }
        }
    }
}
