#pragma warning disable AS0072
namespace Microsoft.SubscriptionBilling;

using Microsoft.CRM.RoleCenters;
using Microsoft.PowerBIReports;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

pageextension 8018 "Sales Rel. Mgr. RC Sub. Bill." extends "Sales & Relationship Mgr. RC"
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
                    ToolTip = 'View or edit Subscription details and lines.';
                }
                action(CustomerContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Sub. Contracts';
                    Image = Customer;
                    RunObject = page "Customer Contracts";
                    ToolTip = 'View or edit Customer Subscription Contract details and assigned subscriptions.';
                }
                action(VendorContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Sub. Contracts';
                    Image = Vendor;
                    RunObject = page "Vendor Contracts";
                    ToolTip = 'View or edit Vendor Subscription Contract details and assigned subscriptions.';
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
                    ToolTip = 'View a consolidated overview of all subscription report pages, conveniently embedded into a single page for easy access.';
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
                        ToolTip = 'View all sales Power BI reports consolidated into a single page for easy access.';
                    }
                    action("Sales Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Overview";
                        ToolTip = 'View a comprehensive overview of sales performance, including Total Sales, Gross Profit Margin, Number of New Customers, and top-performing customers and salespeople.';
                    }
                    action("Daily Sales (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Daily Sales (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Daily Sales";
                        ToolTip = 'View a detailed analysis of sales amounts by weekday with conditional formatting to display figures in a gradient from low to high.';
                    }
                    action("Sales Moving Average (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Average (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Average";
                        ToolTip = 'View the 30-day moving average of sales amounts over time to identify trends by smoothing out fluctuations and highlighting overall patterns.';
                    }
                    action("Sales Moving Annual Total (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Annual Total (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Annual Total";
                        ToolTip = 'View a rolling 12-month view of sales figures, tracking the current year to the previous year''s performance.';
                    }
                    action("Sales Period-Over-Period (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Period-Over-Period (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Period-Over-Period";
                        ToolTip = 'Compare sales performance across different periods, such as month-over-month or year-over-year.';
                    }
                    action("Sales Month-To-Date (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Month-To-Date (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Month-To-Date";
                        ToolTip = 'Track the accumulation of sales amounts throughout the current month, providing insights into progress and performance up to the present date.';
                    }
                    action("Sales by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Item";
                        ToolTip = 'View sales performance by item category, including Sales Amount, Gross Profit Margin, and Gross Profit as a Percent of the Grand Total.';
                    }
                    action("Sales by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Customer";
                        ToolTip = 'View sales performance by customer, including Sales Amount, Cost Amount, Gross Profit, and Gross Profit Margin.';
                    }
                    action("Sales by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Salesperson";
                        ToolTip = 'View salesperson performance by customer and item, including Sales Amount, Sales Quantity, Gross Profit, and Gross Profit Margin.';
                    }
                    action("Sales Actual vs. Budget Qty. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Actual vs. Budget (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Actual vs. Budget Qty.";
                        ToolTip = 'Compare sales quantity to budget amounts and quantities with variance and variance percentage metrics.';
                    }
                    action("Sales Demographics (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Demographics (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Demographics";
                        ToolTip = 'View sales data segmented by demographic factors, including item category, customer posting group, document type, and customer locations.';
                    }
                    action("Sales Decomposition (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Decomposition (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Decomposition";
                        ToolTip = 'View a breakdown of sales figures by contributing factors, including location names, item categories, and countries and regions.';
                    }
                    action("Key Sales Influencers (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Sales Influencers (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Key Sales Influencers";
                        ToolTip = 'Identify and analyze the main factors influencing sales performance based on items, customers, and dimensions.';
                    }
                    action("Opportunity Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opportunity Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Opportunity Overview";
                        ToolTip = 'View sales opportunities, including the number of opportunities, estimated values, sales cycle, and a breakdown of potential value by location.';
                    }
                    action("Sales Quote Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Quote Overview";
                        ToolTip = 'View sales quote details, including the number of quotes, total value, profit rates, and sales quote amount over time.';
                    }
                    action("Return Order Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Order Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Return Order Overview";
                        ToolTip = 'View return order details, including return amounts, quantities, reasons for return, and the financial impact on the organization.';
                    }
                    action("Sales Forecasting (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Forecasting (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Forecasting";
                        ToolTip = 'View sales trend predictions, including forecasting of sales metrics across item, customer, document type, and salespeople.';
                    }
                    action("Sales by Projects (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Projects (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Projects";
                        ToolTip = 'View sales performance by project, including metrics across customer, item, resources, and general ledger accounts.';
                    }
                    action("Customer Retention Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention Overview";
                        ToolTip = 'Analyze customer retention, including repeat purchase behavior, customer loyalty, and trends in customer churn over time.';
                    }
                    action("Customer Retention History (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention History (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention History";
                        ToolTip = 'View historical customer retention metrics and analyze retention trends over time.';
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
                        ToolTip = 'View a consolidated overview of all subscription report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("Subscription Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Subscription Overview Power BI";
                        ToolTip = 'View subscription performance, including Monthly Recurring Revenue, Total Contract Value, Churn, and top-performing customers or vendors.';
                    }
                    action("Revenue YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue YoY Power BI";
                        ToolTip = 'Compare Monthly Recurring Revenue performance across a year-over-year period.';
                    }
                    action("Revenue Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Analysis Power BI";
                        ToolTip = 'View Monthly Recurring Revenue by various dimensions such as billing rhythm, contract type, or customer.';
                    }
                    action("Revenue Development (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Development (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Development Power BI";
                        ToolTip = 'View the change in Monthly Recurring Revenue and identify its sources such as churn, downgrades, new subscriptions, or upgrades.';
                    }
                    action("Churn Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Churn Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Churn Analysis Power BI";
                        ToolTip = 'View churn by various dimensions such as contract term, contract type, or product.';
                    }
                    action("Revenue by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Item Power BI";
                        ToolTip = 'View subscription performance by item category, including Monthly Recurring Revenue, Monthly Recurring Cost, and Monthly Net Profit.';
                    }
                    action("Revenue by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Customer Power BI";
                        ToolTip = 'View subscription performance by customer and item, including Monthly Recurring Revenue, Monthly Recurring Cost, and Monthly Net Profit.';
                    }
                    action("Revenue by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Rev. by Salesperson Power BI";
                        ToolTip = 'View subscription performance by salesperson, including Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit, and Churn.';
                    }
                    action("Total Contract Value YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Value YoY Power BI";
                        ToolTip = 'Compare Total Contract Value and Active Customers across a year-over-year period.';
                    }
                    action("Total Contract Value Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Val Analysis Power BI";
                        ToolTip = 'View Total Contract Value by various dimensions such as billing rhythm, contract type, or customer.';
                    }
                    action("Customer Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Deferrals Power BI";
                        ToolTip = 'View an overview of deferred vs. released subscription sales amount.';
                    }
                    action("Vendor Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Vendor Deferrals Power BI";
                        ToolTip = 'View an overview of deferred vs. released subscription cost amount.';
                    }
                    action("Sales and Cost forecast (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales and Cost forecast (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Cost forecast Power BI";
                        ToolTip = 'View the forecast of Monthly Recurring Revenue and Monthly Recurring Cost by salesperson and customer for future months and years.';
                    }
                    action("Billing Schedule (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Billing Schedule (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Billing Schedule Power BI";
                        ToolTip = 'View a forecast of vendor and customer invoiced amounts according to the contractual billing rhythm.';
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
                    ToolTip = 'Manage usage data suppliers that provide data for processing and billing. Link suppliers to vendors and configure connector-specific defaults.';
                }
                action("Usage Data Imports")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Imports';
                    RunObject = page "Usage Data Imports";
                    ToolTip = 'View and process usage data imports for billing. Import reconciliation files and generate invoices for each usage data supplier.';
                }
                action("Usage Data Subscriptions")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supp. Subscriptions';
                    RunObject = page "Usage Data Subscriptions";
                    ToolTip = 'View supplier subscription data required for processing and billing usage data. Each entry represents a customer subscription from a usage data supplier.';
                }
                action("Usage Data Supplier References")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supplier References';
                    RunObject = page "Usage Data Supp. References";
                    ToolTip = 'View and manage references that link usage data supplier entries to Business Central records.';
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
                ToolTip = 'Create billing proposals for recurring subscriptions and contracts, and generate invoices from the proposals.';
            }
            action("Contract Deferrals Release")
            {
                ApplicationArea = All;
                RunObject = report "Contract Deferrals Release";
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
                }
                action("Customer Contract Deferrals Analysis")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Subscription Contract Deferrals Analysis';
                    Image = "Report";
                    RunObject = Report "Cust. Contr. Def. Analysis";
                }
                action("Vendor Contract Deferrals Analysis")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Subscription Contract Deferrals Analysis';
                    Image = "Report";
                    RunObject = Report "Vend Contr. Def. Analysis";
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
                ToolTip = 'View or edit Subscription Package Line Templates.';
            }
            action(ServiceCommitmentPackage)
            {
                ApplicationArea = All;
                Caption = 'Subscription Package';
                Image = ServiceLedger;
                RunObject = page "Service Commitment Package";
                RunPageMode = Create;
                ToolTip = 'View or edit Subscription Package details and lines.';
            }
            action(ServiceObject)
            {
                ApplicationArea = All;
                Caption = 'Subscription';
                Image = NewOrder;
                RunObject = Page "Service Object";
                RunPageMode = Create;
                ToolTip = 'View or edit Subscription details and lines.';
            }
            action(CustomerContract)
            {
                ApplicationArea = All;
                Caption = 'Customer Subscription Contract';
                Image = NewOrder;
                RunObject = page "Customer Contract";
                RunPageMode = Create;
                ToolTip = 'View or edit Customer Subscription Contract details and assigned subscriptions.';
            }
            action(VendorContract)
            {
                ApplicationArea = All;
                Caption = 'Vendor Subscription Contract';
                Image = NewOrder;
                RunObject = page "Vendor Contract";
                RunPageMode = Create;
                ToolTip = 'View or edit Vendor Subscription Contract details and assigned subscriptions.';
            }
        }
    }
}
