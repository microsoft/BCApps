// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;


using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

page 9036 "Bookkeeper Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            cuegroup(Payables)
            {
                Caption = 'Payables';
                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor Ledger Entries";
                }
                field("Vendors - Payment on Hold"; Rec."Vendors - Payment on Hold")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor List";
                }
                field("Approved Purchase Orders"; Rec."Approved Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                }

                actions
                {
                    action("Edit Payment Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Payment Journal';
                        RunObject = Page "Payment Journal";
                        ToolTip = 'Pay your vendors by filling the payment journal automatically according to payments due, and potentially export all payment to your bank for automatic processing.';
                    }
                    action("New Purchase Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Purchase Credit Memo';
                        RunObject = Page "Purchase Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Create a new purchase credit memo so you can manage returned items to a vendor.';
                    }
                }
            }
            cuegroup(Receivables)
            {
                Caption = 'Receivables';
                field("SOs Pending Approval"; Rec."SOs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                }
                field("Overdue Sales Documents"; Rec."Overdue Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer Ledger Entries";
                }
                field("Approved Sales Orders"; Rec."Approved Sales Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                }

                actions
                {
                    action("Edit Cash Receipt Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Cash Receipt Journal';
                        RunObject = Page "Cash Receipt Journal";
                        ToolTip = 'Register received payments in a cash receipt journal that may already contain journal lines.';
                    }
                    action("New Sales Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Credit Memo';
                        RunObject = Page "Sales Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund by creating a new sales credit memo.';
                    }
                }
            }
            cuegroup("Cash Management")
            {
                Caption = 'Cash Management';
                field("Non-Applied Payments"; Rec."Non-Applied Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Reconciliation Journals';
                    DrillDownPageID = "Pmt. Reconciliation Journals";
                    Image = Cash;
                }

                actions
                {
                    action("New Payment Reconciliation Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payment Reconciliation Journal';
                        ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing bank a bank statement feed or file.';

                        trigger OnAction()
                        var
                            BankAccReconciliation: Record "Bank Acc. Reconciliation";
                        begin
                            BankAccReconciliation.OpenNewWorksheet();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Due Date Filter", '<=%1', WorkDate());
        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
    end;
}

