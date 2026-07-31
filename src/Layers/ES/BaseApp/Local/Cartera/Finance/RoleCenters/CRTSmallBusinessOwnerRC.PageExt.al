// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Bank.Reports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;

pageextension 7000187 "CRT Small Business Owner RC" extends "Small Business Owner RC"
{
    actions
    {
        addlast(reporting)
        {
            group("Cartera Bill Groups")
            {
                Caption = 'Cartera Bill Groups';
                action("Closed Bill Group Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Bill Group Listing';
                    Image = "Report";
                    RunObject = Report "Closed Bill Group Listing";
                    ToolTip = 'View the list of completed bill groups.';
                }
                action("Posted Bill Group Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Bill Group Listing';
                    Image = "Report";
                    RunObject = Report "Posted Bill Group Listing";
                    ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
                }
                action("Bill Group Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill Group Listing';
                    Image = "Report";
                    RunObject = Report "Bill Group Listing";
                    ToolTip = 'View or edit a bill group. Bill groups are receivables documents that are grouped together to submit to a bank for collection. For example, you may want to group documents for the same customer or group documents with the same due date.';
                }
            }
            action("Bank - Summ. Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Summ. Bill Group';
                Image = "Report";
                RunObject = Report "Bank - Summ. Bill Group";
                ToolTip = 'View a detailed summary for existing bill groups.';
            }
            action("Bank - Risk")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Risk';
                Image = "Report";
                RunObject = Report "Bank - Risk";
                ToolTip = 'View the risk status for discounting bills with the selected bank.';
            }
            action("Notice Assignment Credits")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Notice Assignment Credits';
                Image = "Report";
                RunObject = Report "Notice Assignment Credits";
                ToolTip = 'Define how your company decides to administer its billing using a factoring (factor) entity. You send your customers a notification letter, telling them that it is going to assign its billing to another entity. As of that moment, the client will no longer have to pay the company, they will pay the factoring entity instead.';
            }
            separator(Action1100023)
            {
            }
            group("Cartera Payment Orders")
            {
                Caption = 'Cartera Payment Orders';
                action("Closed Payment Order Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Payment Order Listing';
                    Image = "Report";
                    RunObject = Report "Closed Payment Order Listing";
                    ToolTip = 'View the list of completed payment orders.';
                }
                action("Posted Payment Order Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Payment Order Listing';
                    Image = "Report";
                    RunObject = Report "Posted Payment Order Listing";
                    ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
                }
                action("Payment Order Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order Listing';
                    Image = "Report";
                    RunObject = Report "Payment Order Listing";
                    ToolTip = 'View or edit payment orders that represent payables to submit to the bank as a file for electronic payment.';
                }
            }
        }
        addafter("Sales Orders")
        {
            action("Bill Groups List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill Groups List';
                RunObject = Page "Bill Groups List";
                ToolTip = 'View or edit a bill group. Bill groups are receivables documents that are grouped together to submit to a bank for collection. For example, you may want to group documents for the same customer or group documents with the same due date.';
            }
            action("Posted Bill Groups List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Bill Groups List';
                RunObject = Page "Posted Bill Groups List";
                ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
            }
        }
        addafter("Purchase Orders")
        {
            action("Payment Orders List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Orders List';
                RunObject = Page "Payment Orders List";
                ToolTip = 'View or edit payment orders that represent payables to submit to the bank as a file for electronic payment.';
            }
            action("Posted Payment Orders List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Payment Orders List';
                RunObject = Page "Posted Payment Orders List";
                ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
            }
        }
        addlast(Journals)
        {
            action("Cartera Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cartera Journal';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Cartera));
                ToolTip = 'Prepare to post entries for Cartera documents, which are bills and invoices for customers and vendors. There are two types of bills: receivable bills and payable bills. Receivable bills are sent to a customer to be credited after their due date arrives. Payable bills are sent to a customer from a vendor in order to receive payment when the due date arrives.';
            }
        }
        addafter("Posted Sales Credit Memos")
        {
            action("Receivable Closed Cartera Docs")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivable Closed Cartera Docs';
                RunObject = Page "Receivable Closed Cartera Docs";
                ToolTip = 'View the customer bills and invoices that are in the closed bill groups.';
            }
            action("Closed Bill Groups List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closed Bill Groups List';
                RunObject = Page "Closed Bill Groups List";
                ToolTip = 'View the list of completed bill groups.';
            }
        }
        addafter("Posted Purchase Credit Memos")
        {
            action("Payable Closed Cartera Docs")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payable Closed Cartera Docs';
                RunObject = Page "Payable Closed Cartera Docs";
                ToolTip = 'View the vendor bills and invoices that are in closed bill groups.';
            }
            action("Closed Payment Orders List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closed Payment Orders List';
                RunObject = Page "Closed Payment Orders List";
                ToolTip = 'View the list of completed payment orders.';
            }
        }
        addafter("Sales Credit &Memo")
        {
            action("Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill Group';
                Image = VoucherGroup;
                RunObject = Page "Bill Groups";
                ToolTip = 'View or edit a bill group. Bill groups are receivables documents that are grouped together to submit to a bank for collection. For example, you may want to group documents for the same customer or group documents with the same due date.';
            }
            action("Payment Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Order';
                RunObject = Page "Payment Orders";
                ToolTip = 'Create a new payment order to submit payables as a file to the bank for electronic payment.';
            }
        }
        addafter("&Bank Account Reconciliation")
        {
            action("Posted Bill Group Select.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Bill Group Select.';
                RunObject = Page "Posted Bill Group Select.";
                ToolTip = 'View or edit where ledger entries are posted when you post a bill group.';
            }
            group("Bill Group - Export Formats")
            {
                Caption = 'Bill Group - Export Formats';
                action("Payment Order - Export N34")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order - Export N34';
                    Image = "Report";
                    RunObject = Report "Payment order - Export N34";
                    ToolTip = 'Send the payment orders to magnetic media, following the Higher Banking Council''s (CSB) guidelines (Norm 34).';
                }
                action("Bill Group - Export Factoring")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill Group - Export Factoring';
                    Image = "Report";
                    RunObject = Report "Bill group - Export factoring";
                    ToolTip = 'Send the factoring bill groups to a magnetic media.';
                }
            }
        }
        addafter("S&ales && Receivables Setup")
        {
            action("Cartera Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cartera Setup';
                RunObject = Page "Cartera Setup";
                ToolTip = 'Configure your company''s policies for bill groups and payment orders.';
            }
        }
    }
}
