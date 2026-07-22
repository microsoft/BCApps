// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Reports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

pageextension 7000153 "CRT Bank Account List" extends "Bank Account List"
{
    actions
    {
        addlast("&Bank Acc.")
        {
            separator(Action1100000)
            {
            }
            action("&Operation Fees")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Operation Fees';
                Image = Costs;
                RunObject = Page "Operation Fees";
                RunPageLink = Code = field("Operation Fees Code"),
                              "Currency Code" = field("Currency Code");
                ToolTip = 'View the various operation fees that banks charge to process the documents that are remitted to them. These operations include collections, discounts, discount interest, rejections, payment orders, unrisked factoring, and risked factoring.';
            }
            action("Customer Ratings")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Ratings';
                Image = CustomerRating;
                RunObject = Page "Customer Ratings";
                RunPageLink = Code = field("Customer Ratings Code"),
                              "Currency Code" = field("Currency Code");
                ToolTip = 'View or edit the risk percentages that are assigned to customers according to their insolvency risk.';
            }
            action("Sufi&xes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sufi&xes';
                Image = NumberSetup;
                RunObject = Page Suffixes;
                RunPageLink = "Bank Acc. Code" = field("No.");
                ToolTip = 'View the bank suffixes that area assigned to manage bill groups. Typically, banks assign the company a different suffix for managing bill groups, depending if they are receivable or discount management type operations.';
            }
            separator(Action1100004)
            {
            }
            action("Bill &Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill &Groups';
                Image = VoucherGroup;
                RunObject = Page "Bill Groups List";
                RunPageLink = "Bank Account No." = field("No.");
                RunPageView = sorting("Bank Account No.");
                ToolTip = 'View the related bill groups.';
            }
            action("&Posted Bill Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Posted Bill Groups';
                Image = PostedVoucherGroup;
                RunObject = Page "Posted Bill Groups List";
                RunPageLink = "Bank Account No." = field("No.");
                RunPageView = sorting("Bank Account No.");
                ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
            }
            separator(Action1100007)
            {
            }
            action("Payment O&rders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment O&rders';
                Image = Payment;
                RunObject = Page "Payment Orders List";
                RunPageLink = "Bank Account No." = field("No.");
                RunPageView = sorting("Bank Account No.");
                ToolTip = 'View or edit related payment orders.';
            }
            action("Posted P&ayment Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted P&ayment Orders';
                Image = PostedPayment;
                RunObject = Page "Posted Payment Orders List";
                RunPageLink = "Bank Account No." = field("No.");
                RunPageView = sorting("Bank Account No.");
                ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
            }
            separator(Action1100010)
            {
            }
            action("Posted Recei&vable Bills")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Recei&vable Bills';
                Image = PostedReceivableVoucher;
                RunObject = Page "Bank Cat. Posted Receiv. Bills";
                ToolTip = 'View the list of posted bill groups pertaining to receivables.';
            }
            action("Posted Pa&yable Bills")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Pa&yable Bills';
                Image = PostedPayableVoucher;
                RunObject = Page "Bank Cat. Posted Payable Bills";
                ToolTip = 'View the list of posted bill groups pertaining to payables.';
            }
        }
        addlast(reporting)
        {
            action("Bank - Summ. Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Summ. Bill Group';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank - Summ. Bill Group";
                ToolTip = 'View a detailed summary for existing bill groups.';
            }
            action("Bank - Risk")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Risk';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank - Risk";
                ToolTip = 'View the risk status for discounting bills with the selected bank.';
            }
        }
    }
}
