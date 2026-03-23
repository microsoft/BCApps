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
                }
                action(CustomerContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Sub. Contracts';
                    Image = Customer;
                    RunObject = page "Customer Contracts";
                }
                action(VendorContracts)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Sub. Contracts';
                    Image = Vendor;
                    RunObject = page "Vendor Contracts";
                }
                action(OverdueServiceCommitments)
                {
                    ApplicationArea = All;
                    Caption = 'Overdue Subscription Lines';
                    Image = ServiceLedger;
                    RunObject = page "Overdue Service Commitments";
                }
                action("Subscription Billing Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Billing (Power BI)';
                    Image = "PowerBI";
                    RunObject = page "Sub. Billing Report Power BI";
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
                    }
                    action("Sales Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Overview";
                    }
                    action("Daily Sales (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Daily Sales (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Daily Sales";
                    }
                    action("Sales Moving Average (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Average (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Average";
                    }
                    action("Sales Moving Annual Total (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Moving Annual Total (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Moving Annual Total";
                    }
                    action("Sales Period-Over-Period (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Period-Over-Period (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Period-Over-Period";
                    }
                    action("Sales Month-To-Date (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Month-To-Date (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Month-To-Date";
                    }
                    action("Sales by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Item";
                    }
                    action("Sales by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Customer";
                    }
                    action("Sales by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Salesperson";
                    }
                    action("Sales Actual vs. Budget Qty. (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Actual vs. Budget (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Actual vs. Budget Qty.";
                    }
                    action("Sales Demographics (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Demographics (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Demographics";
                    }
                    action("Sales Decomposition (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Decomposition (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Decomposition";
                    }
                    action("Key Sales Influencers (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Sales Influencers (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Key Sales Influencers";
                    }
                    action("Opportunity Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opportunity Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Opportunity Overview";
                    }
                    action("Sales Quote Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Quote Overview";
                    }
                    action("Return Order Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Order Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Return Order Overview";
                    }
                    action("Sales Forecasting (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Forecasting (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Forecasting";
                    }
                    action("Sales by Projects (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales by Projects (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales by Projects";
                    }
                    action("Customer Retention Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention Overview";
                    }
                    action("Customer Retention History (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Retention History (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Retention History";
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
                    }
                    action("Subscription Overview (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Subscription Overview (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Subscription Overview Power BI";
                    }
                    action("Revenue YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue YoY Power BI";
                    }
                    action("Revenue Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Analysis Power BI";
                    }
                    action("Revenue Development (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue Development (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue Development Power BI";
                    }
                    action("Churn Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Churn Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Churn Analysis Power BI";
                    }
                    action("Revenue by Item (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Item (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Item Power BI";
                    }
                    action("Revenue by Customer (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Customer (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Revenue by Customer Power BI";
                    }
                    action("Revenue by Salesperson (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revenue by Salesperson (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Rev. by Salesperson Power BI";
                    }
                    action("Total Contract Value YoY (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value YoY (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Value YoY Power BI";
                    }
                    action("Total Contract Value Analysis (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Contract Value Analysis (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Contract Val Analysis Power BI";
                    }
                    action("Customer Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Customer Deferrals Power BI";
                    }
                    action("Vendor Deferrals (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Deferrals (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Vendor Deferrals Power BI";
                    }
                    action("Sales and Cost forecast (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales and Cost forecast (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Sales Cost forecast Power BI";
                    }
                    action("Billing Schedule (Power BI)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Billing Schedule (Power BI)';
                        Image = "PowerBI";
                        RunObject = page "Billing Schedule Power BI";
                    }
                }
            }
            group(UsageData)
            {
                Caption = 'Usage Data';
                action("Usage Data Suppliers")
                {
                    ApplicationArea = All;
                    RunObject = page "Usage Data Suppliers";
                }
                action("Usage Data Imports")
                {
                    ApplicationArea = All;
                    RunObject = page "Usage Data Imports";
                }
                action("Usage Data Subscriptions")
                {
                    ApplicationArea = All;
                    Caption = 'Usage Data Supp. Subscriptions';
                    RunObject = page "Usage Data Subscriptions";
                }
                action("Usage Data Supplier References")
                {
                    ApplicationArea = All;
                    RunObject = page "Usage Data Supp. References";
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
                }
                action("Contract Types")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Contract Types';
                    Image = FileContract;
                    RunObject = page "Contract Types";
                }
                action("Service Commitment Templates")
                {
                    ApplicationArea = All;
                    Caption = 'Sub. Package Line Templates';
                    Image = Template;
                    RunObject = page "Service Commitment Templates";
                }
                action("Service Commitment Packages")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Packages';
                    Image = Template;
                    RunObject = page "Service Commitment Packages";
                }
            }
        }
        addlast(processing)
        {
            action("Recurring Billing")
            {
                ApplicationArea = All;
                RunObject = page "Recurring Billing";
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
            }
            action(ServiceCommitmentPackage)
            {
                ApplicationArea = All;
                Caption = 'Subscription Package';
                Image = ServiceLedger;
                RunObject = page "Service Commitment Package";
                RunPageMode = Create;
            }
            action(ServiceObject)
            {
                ApplicationArea = All;
                Caption = 'Subscription';
                Image = NewOrder;
                RunObject = Page "Service Object";
                RunPageMode = Create;
            }
            action(CustomerContract)
            {
                ApplicationArea = All;
                Caption = 'Customer Subscription Contract';
                Image = NewOrder;
                RunObject = page "Customer Contract";
                RunPageMode = Create;
            }
            action(VendorContract)
            {
                ApplicationArea = All;
                Caption = 'Vendor Subscription Contract';
                Image = NewOrder;
                RunObject = page "Vendor Contract";
                RunPageMode = Create;
            }
        }
    }
}
