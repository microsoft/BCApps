// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

page 9034 "Acc. Receivable Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Overdue Sales Documents"; Rec."Overdue Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer Ledger Entries";
                }
                field("Sales Return Orders - All"; Rec."Sales Return Orders - All")
                {
                    ApplicationArea = SalesReturnOrder;
                    DrillDownPageID = "Sales Return Order List";
                }
                field("Customers - Blocked"; Rec."Customers - Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer List";
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
            cuegroup("Document Approvals")
            {
                Caption = 'Document Approvals';
                field("SOs Pending Approval"; Rec."SOs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
                }
                field("Approved Sales Orders"; Rec."Approved Sales Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Sales Order List";
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

        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
    end;
}

