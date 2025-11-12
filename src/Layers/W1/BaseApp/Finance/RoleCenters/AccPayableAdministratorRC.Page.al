// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Intercompany;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using System.Automation;
using System.Threading;

page 9045 "Acc. Payable Administrator RC"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Accounts Payable Administrator';
    PageType = RoleCenter;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(RoleCenter)
        {
            part(HeadlineRCAPAdministtrator; "Headline RC A/P Admin")
            {
            }
            part(APAdministratorActivities; "Acc. Payable Activities")
            {
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Suite;
            }
            part("Intercompany Activities"; "Intercompany Activities")
            {
                ApplicationArea = Intercompany;
            }
            part(JobQueueActivities; "Job Queue Activities")
            {
            }
            part(TeamMemberActvities; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part(MyVendors; "My Vendors")
            {
            }
            part(OverduePurchaseInvoices; "Overdue Purchase Invoices")
            {
            }
            part(PayablePerformance; "Acc. Payable Performance")
            {
            }
            part("Report Inbox Part"; "Report Inbox Part")
            {
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(Vendors)
            {
                Caption = 'Vendors';
                RunObject = Page "Vendor List";
                ToolTip = 'View and manage vendors.';
            }
            action(PurchaseOrders)
            {
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Orders";
                ToolTip = 'View and manage purchase orders.';
            }
            action(PurchaseInvoices)
            {
                Caption = 'Purchase Invoices';
                RunObject = Page "Purchase Invoices";
                ToolTip = 'View and manage purchase invoices.';
            }
            action(PurchaseCreditMemos)
            {
                Caption = 'Purchase Credit Memos';
                RunObject = Page "Purchase Credit Memos";
                ToolTip = 'View and manage purchase credit memos.';
            }
            action(PurchaseReturnOrders)
            {
                Caption = 'Purchase Return Orders';
                RunObject = Page "Purchase Return Orders";
                ToolTip = 'View and manage purchase return orders.';
            }
        }
        area(Sections)
        {
            group(PostedDocuments)
            {
                Caption = 'Posted Documents';

                action("Posted Purchase Invoices")
                {
                    Caption = 'Posted Purchase Invoices';
                    RunObject = Page "Posted Purchase Invoices";
                    ToolTip = 'View and manage posted purchase invoices.';
                }
                action("Posted Purchase Credit Memos")
                {
                    Caption = 'Posted Purchase Credit Memos';
                    RunObject = Page "Posted Purchase Credit Memos";
                    ToolTip = 'View and manage posted purchase credit memos.';
                }
            }
            group(ViewPurchaseDocuments)
            {
                Caption = 'Purchase Documents';

                action("Purchase Quotes")
                {
                    Caption = 'Purchase Quotes';
                    RunObject = Page "Purchase Quotes";
                    ToolTip = 'View and manage purchase quotes.';
                }
                action("Purchase Orders")
                {
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Orders";
                    ToolTip = 'View and manage purchase orders.';
                }
                action("Purchase Invoices")
                {
                    Caption = 'Purchase Invoices';
                    RunObject = Page "Purchase Invoices";
                    ToolTip = 'View and manage purchase invoices.';
                }
                action("Purchase Credit Memos")
                {
                    Caption = 'Purchase Credit Memos';
                    RunObject = Page "Purchase Credit Memos";
                    ToolTip = 'View and manage purchase credit memos.';
                }
            }
            group(SectionReports)
            {
                Caption = 'Reports';

                action("Purchase Statistics")
                {
                    Caption = 'Purchase Statistics';
                    RunObject = Report "Purchase Statistics";
                    ToolTip = 'Run the Purchase Statistics report.';
                }
            }
        }
        area(Creation)
        {
            action(CreateVendor)
            {
                Caption = 'Create Vendor';
                RunObject = Page "Vendor Card";
                RunPageMode = Create;
                ToolTip = 'Create a new vendor.';
            }
            action(CreatePayment)
            {
                Caption = 'Create Payment';
                RunObject = Page "Create Payment";
                RunPageMode = Create;
                ToolTip = 'Create a new payment.';
            }
            group(CreatePurchaseDocuments)
            {
                Caption = 'Purchase Documents';

                action("Create Purchase Order")
                {
                    Caption = 'Create Purchase Order';
                    Image = NewOrder;
                    RunObject = Page "Purchase Order";
                    RunPageMode = Create;
                    ToolTip = 'Create a new purchase order.';
                }
                action("Create Purchase Invoice")
                {
                    Caption = 'Create Purchase Invoice';
                    Image = NewInvoice;
                    RunObject = Page "Purchase Invoice";
                    RunPageMode = Create;
                    ToolTip = 'Create a new purchase invoice.';
                }
                action("Create Purchase Credit Memo")
                {
                    Caption = 'Create Purchase Credit Memo';
                    Image = CreateCreditMemo;
                    RunObject = Page "Purchase Credit Memo";
                    RunPageMode = Create;
                    ToolTip = 'Create a new purchase credit memo.';
                }
                action("Create Purchase Return Order")
                {
                    Caption = 'Create Purchase Return Order';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Order";
                    RunPageMode = Create;
                    ToolTip = 'Create a new purchase return order.';
                }
            }
        }
        area(Processing)
        {
            action(FindEntries)
            {
                Caption = 'Find Entries';
                RunObject = Page Navigate;
                ToolTip = 'Find entries in the system.';
            }
            group(Journals)
            {
                Caption = 'Journals';

                action("Payment Reconciliation Journal")
                {
                    Caption = 'Payment Reconciliation Journal';
                    RunObject = Page "Payment Reconciliation Journal";
                    ToolTip = 'Open payment reconciliation journal.';
                }
                action("Purchase Journal")
                {
                    Caption = 'Purchase Journal';
                    RunObject = Page "Purchase Journal";
                    ToolTip = 'Post any purchase transaction for the vendor.';
                }
                action("Payment Journal")
                {
                    Caption = 'Payment Journal';
                    RunObject = Page "Payment Journal";
                    ToolTip = 'Pay your vendors by filling the payment journal automatically according to payments due, and potentially export all payment to your bank for automatic processing.';
                }
                action("General Journal")
                {
                    Caption = 'General Journal';
                    RunObject = Page "General Journal";
                    ToolTip = 'Prepare to post any transaction to the company books.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';

                action(PurchAndPayablesSetup)
                {
                    Caption = 'Purchases & Payables Setup';
                    RunObject = Page "Purchases & Payables Setup";
                    ToolTip = 'Set up the purchasing and payables features.';
                }
                action(GeneralLedgerSetup)
                {
                    Caption = 'General Ledger Setup';
                    RunObject = Page "General Ledger Setup";
                    ToolTip = 'Set up the general ledger features.';
                }
                action(StandardPurchaseCodes)
                {
                    Caption = 'Standard Purchase Codes';
                    RunObject = Page "Standard Purchase Codes";
                    ToolTip = 'Set up standard purchase codes.';
                }
                action(PurchasingCodes)
                {
                    Caption = 'Purchasing Codes';
                    RunObject = Page "Purchasing Codes";
                    ToolTip = 'Set up purchasing codes.';
                }
            }
            group(ActionBarReports)
            {
                Caption = 'Reports';

                action("Aged Accounts Payable")
                {
                    Caption = 'Aged Accounts Payable';
                    RunObject = Report "Aged Accounts Payable";
                    ToolTip = 'View the aged accounts payable report.';
                }
                action(PaymentsOnHold)
                {
                    Caption = 'Payments on Hold';
                    RunObject = Report "Payments on Hold";
                    ToolTip = 'View the payments on hold report.';
                }
                action(PurchaseStatistics)
                {
                    Caption = 'Purchase Statistics';
                    RunObject = Report "Purchase Statistics";
                    ToolTip = 'View the purchase statistics report.';
                }
                action(VendorItemCatalog)
                {
                    Caption = 'Vendor Item Catalog';
                    RunObject = Report "Vendor Item Catalog";
                    ToolTip = 'View the vendor item catalog report.';
                }
                action(VendorRegister)
                {
                    Caption = 'Vendor Register';
                    RunObject = Report "Vendor Register";
                    ToolTip = 'View the vendor register report.';
                }
                action(VendorBalanceToDate)
                {
                    Caption = 'Vendor Balance to Date';
                    RunObject = Report "Vendor - Balance to Date";
                    ToolTip = 'View the vendor balance to date report.';
                }
                action(VendorDetailTrialBalance)
                {
                    Caption = 'Vendor Detail Trial Balance';
                    RunObject = Report "Vendor - Detail Trial Balance";
                    ToolTip = 'View the vendor detail trial balance report.';
                }
                action(VendorLabels)
                {
                    Caption = 'Vendor Labels';
                    RunObject = Report "Vendor - Labels";
                    ToolTip = 'View the vendor labels report.';
                }
                action(VendorList)
                {
                    Caption = 'Vendor List';
                    RunObject = Report "Vendor - List";
                    ToolTip = 'View the vendor list report.';
                }
                action(VendorOrderDetail)
                {
                    Caption = 'Vendor Order Detail';
                    RunObject = Report "Vendor - Order Detail";
                    ToolTip = 'View the vendor order detail report.';
                }
                action(VendorOrderSummary)
                {
                    Caption = 'Vendor Order Summary';
                    RunObject = Report "Vendor - Order Summary";
                    ToolTip = 'View the vendor order summary report.';
                }
                action(VendorPurchaseList)
                {
                    Caption = 'Vendor Purchase List';
                    RunObject = Report "Vendor - Purchase List";
                    ToolTip = 'View the vendor purchase list report.';
                }
                action(VendorSummaryAging)
                {
                    Caption = 'Vendor Summary Aging';
                    RunObject = Report "Vendor - Summary Aging";
                    ToolTip = 'View the vendor summary aging report.';
                }
                action(VendorTop10List)
                {
                    Caption = 'Vendor Top 10 List';
                    RunObject = Report "Vendor - Top 10 List";
                    ToolTip = 'View the vendor top 10 list report.';
                }
                action(VendorTrialBalance)
                {
                    Caption = 'Vendor Trial Balance';
                    RunObject = Report "Vendor - Trial Balance";
                    ToolTip = 'View the vendor trial balance report.';
                }
                action(VendorItemPurchases)
                {
                    Caption = 'Vendor Item Purchases';
                    RunObject = Report "Vendor/Item Purchases";
                    ToolTip = 'View the vendor item purchases report.';
                }
            }
        }
    }
}
