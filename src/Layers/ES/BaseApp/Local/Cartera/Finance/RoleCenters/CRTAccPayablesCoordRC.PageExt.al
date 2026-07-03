// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;

pageextension 7000173 "CRT Acc. Payables Coord. RC" extends "Acc. Payables Coordinator RC"
{
    actions
    {
        addafter(Action63)
        {
            separator(Action1100008)
            {
            }
            action("Vendor - Due Payments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Due Payments';
                Image = "Report";
                RunObject = Report "Vendor - Due Payments";
                ToolTip = 'View a list of payments to be made to a particular vendor sorted by due date.';
            }
            group("Cartera Payment Order")
            {
                Caption = 'Cartera Payment Order';
                action("Closed Payment Order Listing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Payment Order Listing';
                    Image = "Report";
                    RunObject = Report "Closed Payment Order Listing";
                    ToolTip = 'View the list of completed payment orders.';
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
        addafter(GeneralJournals)
        {
            action("Cartera Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cartera Journal';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Cartera),
                                    Recurring = const(false));
                ToolTip = 'Prepare to post entries for Cartera documents, which are bills and invoices for customers and vendors. There are two types of bills: receivable bills and payable bills. Receivable bills are sent to a customer to be credited after their due date arrives. Payable bills are sent to a customer from a vendor in order to receive payment when the due date arrives.';
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
    }
}
