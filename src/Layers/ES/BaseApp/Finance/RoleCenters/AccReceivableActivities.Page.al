// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
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
            cuegroup(Cartera)
            {
                Caption = 'Cartera';
                field("Receivable Documents"; Rec."Receivable Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Receivables Cartera Docs";
                    ToolTip = 'Specifies the receivables document that is associated with the bill group.';
                }
                field("Posted Receivable Documents"; Rec."Posted Receivable Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Posted Cartera Documents";
                    ToolTip = 'Specifies the receivables documents that have been posted.';
                }

                actions
                {
                    action("New Bill Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Bill Group';
                        RunObject = Page "Bill Groups";
                        RunPageMode = Create;
                        ToolTip = 'Create a new group of receivables documents for submission to the bank for electronic collection.';
                    }
                    action("Posted Bill Groups List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Groups List';
                        RunObject = Page "Posted Bill Groups List";
                        ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
                    }
                    action("Posted Bill Group Select.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Bill Group Select.';
                        RunObject = Page "Posted Bill Group Select.";
                        ToolTip = 'View or edit where ledger entries are posted when you post a bill group.';
                    }
                }
            }
            cuegroup(MissingSIIEntries)
            {
                Caption = 'Missing SII Entries';
                field("Missing SII Entries"; Rec."Missing SII Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Missing SII Entries';
                    DrillDownPageID = "Recreate Missing SII Entries";
                    ToolTip = 'Specifies that some posted documents were not transferred to SII.';

                    trigger OnDrillDown()
                    var
                        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
                    begin
                        SIIRecreateMissingEntries.ShowRecreateMissingEntriesPage();
                    end;
                }
                field("Days Since Last SII Check"; Rec."Days Since Last SII Check")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Recreate Missing SII Entries";
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days since the last check for missing SII entries.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalculateCueFieldValues();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
    end;

    local procedure CalculateCueFieldValues()
    var
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        if Rec.FieldActive("Missing SII Entries") then
            Rec."Missing SII Entries" := SIIRecreateMissingEntries.GetMissingEntriesCount();
        if Rec.FieldActive("Days Since Last SII Check") then
            Rec."Days Since Last SII Check" := SIIRecreateMissingEntries.GetDaysSinceLastCheck();
    end;
}

