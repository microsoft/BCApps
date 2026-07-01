// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reports;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;

pageextension 7000163 "CRT Acc. Receivables Adm. RC" extends "Acc. Receivables Adm. RC"
{
    actions
    {
        addafter("Customer - Due Payments")
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
            }
        }
        addafter("Sales Invoices")
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
        addafter("&Sales")
        {
            action("Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill Group';
                Image = VoucherGroup;
                RunObject = Page "Bill Groups";
                ToolTip = 'View or edit a bill group. Bill groups are receivables documents that are grouped together to submit to a bank for collection. For example, you may want to group documents for the same customer or group documents with the same due date.';
            }
        }
        addafter("Combine Return S&hipments")
        {
            separator(Action1100020)
            {
            }
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
    }
}