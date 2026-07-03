namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.RoleCenters;
using Microsoft.PowerBIReports;

pageextension 8080 "Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast("PBI Reports")
        {
            group("Subscription Billing Reports")
            {
                Caption = 'Subscription Billing';
                Image = PowerBI;
                ToolTip = 'Power BI reports for subscription billing.';
                action("Subscription Billing Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Billing Report';
                    Image = "PowerBI";
                    RunObject = page "Sub. Billing Report Power BI";
                    ToolTip = 'The Subscription Billing Report offers a consolidated view of all subscription report pages, conveniently embedded into a single page for easy access.';
                }
                action("Subscription Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Overview';
                    Image = "PowerBI";
                    RunObject = page "Subscription Overview Power BI";
                    ToolTip = 'The Subscription Overview provides a comprehensive view of subscription performance, offering insights into metrics such as Monthly Recurring Revenue, Total Contract Value, Churn and top-performing customers or vendors.';
                }
                action("Revenue YoY")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue YoY';
                    Image = "PowerBI";
                    RunObject = page "Revenue YoY Power BI";
                    ToolTip = 'The Revenue YoY report compares Monthly Recurring Revenue performance across a year-over-year period.';
                }
                action("Revenue Analysis")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue Analysis';
                    Image = "PowerBI";
                    RunObject = page "Revenue Analysis Power BI";
                    ToolTip = 'The Revenue Analysis report breaks down Monthly Recurring Revenue by various dimension such as billing rhythm, contract type or customer.';
                }
                action("Revenue Development")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue Development';
                    Image = "PowerBI";
                    RunObject = page "Revenue Development Power BI";
                    ToolTip = 'The Revenue Development report shows the change in monthly recurring revenue and helps to identify its various sources such as churn, downgrades, new subscriptions or upgrades.';
                }
                action("Churn Analysis")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Churn Analysis';
                    Image = "PowerBI";
                    RunObject = page "Churn Analysis Power BI";
                    ToolTip = 'The Churn Analysis report breaks down churn by various dimensions such as contract term, contract type or product.';
                }
                action("Revenue by Item")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue by Item';
                    Image = "PowerBI";
                    RunObject = page "Revenue by Item Power BI";
                    ToolTip = 'The Revenue by Item report breaks down subscription performance by item category, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which categories and items are driving subscription revenue and profitability.';
                }
                action("Revenue by Customer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue by Customer';
                    Image = "PowerBI";
                    RunObject = page "Revenue by Customer Power BI";
                    ToolTip = 'The Revenue by Customer report breaks down subscription performance by customer and item, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Monthly Net Profit %. This report provides detailed insights into which customers and items are driving subscription revenue and profitability.';
                }
                action("Revenue by Salesperson")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revenue by Salesperson';
                    Image = "PowerBI";
                    RunObject = page "Rev. by Salesperson Power BI";
                    ToolTip = 'The Revenue by Salesperson report breaks down subscription performance by Salesperson, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Churn.';
                }
                action("Total Contract Value YoY")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Contract Value YoY';
                    Image = "PowerBI";
                    RunObject = page "Contract Value YoY Power BI";
                    ToolTip = 'The Total Contract Value YoY report compares the Total Contract Value and Active Customers across a year-over-year period.';
                }
                action("Total Contract Value Analysis")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Contract Value Analysis';
                    Image = "PowerBI";
                    RunObject = page "Contract Val Analysis Power BI";
                    ToolTip = 'The Total Contract Value Analysis report breaks down Total Contract Value by various dimension such as billing rhythm, contract type or customer.';
                }
                action("Customer Deferrals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Deferrals';
                    Image = "PowerBI";
                    RunObject = page "Customer Deferrals Power BI";
                    ToolTip = 'The Customer Deferrals report provides an overview of deferred vs. released subscription sales amount.';
                }
                action("Vendor Deferrals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Deferrals';
                    Image = "PowerBI";
                    RunObject = page "Vendor Deferrals Power BI";
                    ToolTip = 'The Vendor Deferrals report provides an overview of deferred vs. released subscription cost amount.';
                }
                action("Sales and Cost forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales and Cost forecast';
                    Image = "PowerBI";
                    RunObject = page "Sales Cost forecast Power BI";
                    ToolTip = 'The Sales and Cost forecast report provides the forecast of Monthly Recurring Revenue and Monthly Recurring Cost for the future months and years. This report provides detailed insights into which salespersons and customers are driving future subscription performance.';
                }
                action("Billing Schedule")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Billing Schedule';
                    Image = "PowerBI";
                    RunObject = page "Billing Schedule Power BI";
                    ToolTip = 'The Billing Schedule report provides a forecast of vendor and customer invoiced amounts according to the contractual billing rhythm. It helps to identify future development of incoming and outgoing cash from billed subscriptions.';
                }
            }
        }
    }
#if not CLEAN26
    layout
    {
        addafter(Control46)
        {
            part(SubBillingActivities; "Sub. Billing Activities")
            {
                ObsoleteReason = 'Removed as Subscription Billing is not relevant in context of Business Manager.';
                ObsoleteState = Pending;
                ObsoleteTag = '26.0';
                Visible = false;
                ApplicationArea = All;
                Caption = 'Subscription Billing';
            }
        }
    }
#endif
}
