namespace Microsoft.SubscriptionBilling;

using Microsoft.CRM.RoleCenters;
using Microsoft.PowerBIReports;

pageextension 8019 "Sales Mkt. Mgr. RC SubBill" extends "Sales & Marketing Manager RC"
{
    actions
    {
        addafter(Group7)
        {
            group(SubscriptionBilling)
            {
                Caption = 'Subscription Billing';
                action(SubBillSubscriptions)
                {
                    ApplicationArea = All;
                    Caption = 'Subscriptions';
                    Image = ServiceSetup;
                    RunObject = page "Service Objects";
                    ToolTip = 'View or edit detailed information on Subscriptions and the Subscription Lines that belong to them.';
                }
                action(SubBillCustomerContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Sub. Contracts';
                    Image = Customer;
                    RunObject = page "Customer Contracts";
                    ToolTip = 'View or edit detailed information on Customer Subscription Contracts that include recurring subscriptions.';
                }
                action(SubBillVendorContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Sub. Contracts';
                    Image = Vendor;
                    RunObject = page "Vendor Contracts";
                    ToolTip = 'View or edit detailed information on Vendor Subscription Contracts that include recurring subscriptions.';
                }
                action(SubBillRecurringBilling)
                {
                    ApplicationArea = All;
                    Caption = 'Recurring Billing';
                    RunObject = page "Recurring Billing";
                    ToolTip = 'Opens the page for creating billing proposals for Recurring subscriptions.';
                }
                action(SubBillUsageDataSuppliers)
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Suppliers';
                    RunObject = page "Usage Data Suppliers";
                    ToolTip = 'Opens the list of Usage Data Suppliers.';
                }
                action(SubBillUsageDataImports)
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Imports';
                    RunObject = page "Usage Data Imports";
                    ToolTip = 'Opens the list of Usage Data Imports.';
                }
                action(SubBillUsageDataSubscriptions)
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supp. Subscriptions';
                    RunObject = page "Usage Data Subscriptions";
                    ToolTip = 'Opens the list of Usage Data Subscriptions.';
                }
                action(SubBillUsageDataSuppReferences)
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supplier References';
                    RunObject = page "Usage Data Supp. References";
                    ToolTip = 'Opens the list of Usage Data Supplier References.';
                }
                action(SubBillContractSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Contract Setup';
                    Image = ServiceAgreement;
                    RunObject = page "Service Contract Setup";
                    ToolTip = 'View or edit Subscription Contract Setup.';
                }
                action(SubBillContractTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Contract Types';
                    Image = FileContract;
                    RunObject = page "Contract Types";
                    ToolTip = 'View or edit Subscription Contract Types.';
                }
                action(SubBillPackageLineTemplates)
                {
                    ApplicationArea = All;
                    Caption = 'Sub. Package Line Templates';
                    Image = Template;
                    RunObject = page "Service Commitment Templates";
                    ToolTip = 'View or edit Subscription Package Line Templates.';
                }
                action(SubBillPackages)
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Packages';
                    Image = Template;
                    RunObject = page "Service Commitment Packages";
                    ToolTip = 'View or edit Subscription Packages.';
                }
                group(SubBillingReports)
                {
                    Caption = 'Reports';
                    action(SubBillOverviewOfContractComp)
                    {
                        ApplicationArea = All;
                        Caption = 'Overview of Subscription Contract components';
                        Image = "Report";
                        RunObject = Report "Overview Of Contract Comp";
                        ToolTip = 'Analyze components of your contracts.';
                    }
                    action(SubBillCustContrDefAnalysis)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer Sub. Contract Deferrals Analysis';
                        Image = "Report";
                        RunObject = Report "Cust. Contr. Def. Analysis";
                        ToolTip = 'Analyze Customer Subscription Contract deferrals.';
                    }
                    action(SubBillVendContrDefAnalysis)
                    {
                        ApplicationArea = All;
                        Caption = 'Vendor Sub. Contract Deferrals Analysis';
                        Image = "Report";
                        RunObject = Report "Vend Contr. Def. Analysis";
                        ToolTip = 'Analyze Vendor Subscription Contract deferrals.';
                    }
                }
                group(SubBillingPowerBIReports)
                {
                    Caption = 'Power BI Reports';
                    action("SubBill Report (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Billing Report (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sub. Billing Report Power BI";
                        ToolTip = 'The Subscription Billing Report offers a consolidated view of all subscription report pages, conveniently embedded into a single page for easy access.';
                    }
                    action("SubBill Sub. Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Subscription Overview Power BI";
                        ToolTip = 'The Subscription Overview provides a comprehensive view of subscription performance, offering insights into metrics such as Monthly Recurring Revenue, Total Contract Value, Churn and top-performing customers or vendors.';
                    }
                    action("SubBill Revenue YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue YoY Power BI";
                        ToolTip = 'The Revenue YoY report compares Monthly Recurring Revenue performance across a year-over-year period.';
                    }
                    action("SubBill Revenue Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Analysis Power BI";
                        ToolTip = 'The Revenue Analysis report breaks down Monthly Recurring Revenue by various dimension such as billing rhythm, contract type or customer.';
                    }
                    action("SubBill Revenue Dev. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Development (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Development Power BI";
                        ToolTip = 'The Revenue Development report shows the change in monthly recurring revenue and helps to identify its various sources such as churn, downgrades, new subscriptions or upgrades.';
                    }
                    action("SubBill Churn Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Churn Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Churn Analysis Power BI";
                        ToolTip = 'The Churn Analysis report breaks down churn by various dimensions such as contract term, contract type or product.';
                    }
                    action("SubBill Revenue by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Item Power BI";
                        ToolTip = 'The Revenue by Item report breaks down subscription performance by item category, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which categories and items are driving subscription revenue and profitability.';
                    }
                    action("SubBill Revenue by Cust. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Customer Power BI";
                        ToolTip = 'The Revenue by Customer report breaks down subscription performance by customer and item, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which customers and items are driving subscription revenue and profitability.';
                    }
                    action("SubBill Rev. by Salesp. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Rev. by Salesperson Power BI";
                        ToolTip = 'The Revenue by Salesperson report breaks down subscription performance by Salesperson, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Churn.';
                    }
                    action("SubBill Contract Val YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Value YoY Power BI";
                        ToolTip = 'The Total Contract Value YoY report compares the Total Contract Value and Active Customers across a year-over-year period.';
                    }
                    action("SubBill Contr. Val Anal. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Val Analysis Power BI";
                        ToolTip = 'The Total Contract Value Analysis report breaks down Total Contract Value by various dimension such as billing rhythm, contract type or customer.';
                    }
                    action("SubBill Cust. Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Deferrals Power BI";
                        ToolTip = 'The Customer Deferrals report provides an overview of deferred vs. released subscription sales amount.';
                    }
                    action("SubBill Vend. Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Vendor Deferrals Power BI";
                        ToolTip = 'The Vendor Deferrals report provides an overview of deferred vs. released subscription cost amount.';
                    }
                    action("SubBill Sales Cost Fcst (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales and Cost forecast (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Cost forecast Power BI";
                        ToolTip = 'The Sales and Cost forecast report provides the forecast of Monthly Recurring Revenue and Monthly Recurring Cost for the future months and years. This report provides detailed insights into which salespersons and customers are driving future subscription performance.';
                    }
                    action("SubBill Billing Sched. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Billing Schedule (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Billing Schedule Power BI";
                        ToolTip = 'The Billing Schedule report provides a forecast of vendor and customer invoiced amounts according to the contractual billing rhythm. It helps to identify future development of incoming and outgoing cash from billed subscriptions.';
                    }
                }
            }
        }
    }
}
